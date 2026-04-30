# /agentforce eval — Regression Testing

Run regression tests against the agent.

Two layers, distinct purposes:
- **Testing Center** — per-action single-turn regression with topic + action assertions (on-platform, `sf agent test run`)
- **REST agent tests** — multi-turn conversations against the deployed agent over the in-org Invocable Action REST endpoint, judged by Claude

---

## Testing Center

### Structure

One consolidated `agent-eval/Regression.aiEvaluationDefinition-meta.xml` with 14 `testCase` blocks — one per action. API name inside `<name>` is `Regression`; run via `sf agent test run --api-name Regression`.

Why a single definition: Salesforce caps concurrent test jobs at **10 per 10-hour window**. Launching 14 per-action tests in parallel hit that cap and threw `TestStartFailed: Too many inflight evaluations`, so we use one definition with multiple cases instead.

### Running in parallel

`sf agent test run --wait` has two issues: it's serial (one at a time) and the CLI polling crashes with `TestPollFailed: no constant with the specified name: RETRY` on ~20% of runs. The test completes server-side even when the CLI dies. Handle both by running multiple parallel passes of the same definition, capturing JSON output to `/tmp/`, and parsing what landed.

```bash
# Run 2 parallel passes of the Regression suite
mkdir -p /tmp/ae && rm -f /tmp/ae/*.json
for i in 1 2; do
  (sf agent test run --api-name Regression --wait 30 --result-format json > "/tmp/ae/Regression_run$i.json" 2>&1) &
done
wait
```

`--wait 30` caps each polling loop at 30 min. The `&` backgrounds each invocation; `wait` blocks until all finish. Two passes is the sweet spot — cheap enough not to trip the concurrency cap, redundant enough that intermittent flakes (Data Cloud routing especially) almost always pass in at least one pass.

### Consolidating results (handles the polling bug)

The CLI captures JSON even when the polling crashes mid-way — the last `{` in the file marks the start of the result document. Each pass's JSON contains 14 `testResults` (one per case). Aggregate across passes: a case is considered passing if it passed in *any* pass.

```bash
python3 <<'PY'
import os, re, json

def find_results(o):
    if isinstance(o, dict):
        if 'testResults' in o: return o['testResults']
        for v in o.values():
            r = find_results(v)
            if r: return r
    if isinstance(o, list):
        for v in o:
            r = find_results(v)
            if r: return r

case_results = {}  # case name → list of statuses across passes
crashed_passes = []
for fn in sorted(os.listdir('/tmp/ae')):
    if not fn.endswith('.json'): continue
    raw = open(f'/tmp/ae/{fn}').read()
    matches = list(re.finditer(r'\n\{\n', raw))
    if not matches:
        crashed_passes.append((fn, 'CLI polling crash — check Testing Center UI'))
        continue
    start = matches[-1].start() + 1
    try:
        d = json.loads(raw[start:])
    except Exception as e:
        crashed_passes.append((fn, f'JSON parse error: {e}'))
        continue
    for r in find_results(d) or []:
        case_results.setdefault(r['name'], []).append(r['result'])

passed = sum(1 for rs in case_results.values() if 'PASS' in rs)
failed = len(case_results) - passed
print(f'PASS {passed}/{len(case_results)}  FAIL {failed}  passes_crashed {len(crashed_passes)}')
for name in sorted(case_results):
    rs = case_results[name]
    if 'PASS' not in rs:
        print(f'  FAIL {name}: {rs}')
for fn, msg in crashed_passes:
    print(f'  CRASH {fn}: {msg}')
PY
```

### Retrying crashes

Polling crashes are CLI-only; the test finished server-side. Two strategies:

1. **Run a third pass** (fast): if both passes crashed, re-invoke `sf agent test run --api-name Regression` once more. Polling hits at a different server state and usually succeeds.
2. **Check the UI**: Setup → Agentforce → Testing Center → the eval run has the real result.

Prefer strategy 1 in scripts; strategy 2 when debugging.

### Deploy

`sf project deploy start --source-dir agent-eval/Regression.aiEvaluationDefinition-meta.xml --concise`

### What each case probes

Each `testCase` block carries three expectations:
- `topic_assertion` — agent routes to the MyOrgButler topic
- `actions_assertion` — agent calls the expected action sequence
- `bot_response_rating` — Salesforce's built-in evaluator grades response content

Goal: 100% on all three, across all 14 cases.

---

## Multi-turn agent tests (REST)

Multi-turn agent specs live in `agent-eval/`:
- `demo-story.yaml` — the conference demo workflow.
- `prompt-regression.yaml` — smoke tests that exercise specific prompt templates (`ConsolidateMemory`, `AnswerFromFile`) through the agent.

Each entry has plain-English `expect` criteria. Claude drives the agent over the in-org Invocable Action REST endpoint, keeps the transcript in memory, and judges each turn against `expect`.

Why this endpoint: the `generateAiAgentResponse` invocable action is exposed at `/services/data/vXX.X/actions/custom/generateAiAgentResponse/<AgentApiName>`. `sf api request rest` hits it with the CLI's existing org auth — no Connected App, no JWT, no api.salesforce.com. Returns `sessionId` + `agentResponse` directly as JSON. Multi-turn works by passing the `sessionId` back into the next call.

What it can't observe: planner trace (which topic routed, which actions invoked). That data lives in Data Cloud DLM tables; the `ConversationDefinitionEventLog` only captures dialog-level events with sensitive fields redacted. Topic/action assertions stay in Testing Center.

### Spec format

Each test has a `name`, a top-level `description` summarizing the scenario, and a `turns:` list. All turns in a test share one agent session — context carries via the returned `sessionId`. Use this layer for scenarios that single-turn Testing Center cases can't capture; per-action regression stays in `Regression.aiEvaluationDefinition-meta.xml`.

```yaml
agent: MyOrgButler

tests:
  - name: SalesRepMondayMorning
    description: "MyOrgButler Demo — A Sales Rep's Monday Morning"
    turns:
      - turn: 'Prioritize: what needs my attention?'
        say: which opportunity should I work on next?
        expect: Recommends the Acme Q1 Expansion Deal as top priority
      - turn: 'Act: create the follow-up'
        say: create a task to call Acme about the discount
        expect: Confirms a task was created on the Acme opportunity, mentions VP approval or discount
```

`expect` is plain English — Claude grades the agent's reply against it. No substring matching. Per-turn `turn` is a short label that surfaces in the run output and helps disambiguate failures.

### Running one test

```bash
ORG=my-org-butler_DEV
AGENT=MyOrgButler
SESSION=""

# Turn 1
body=$(jq -n --arg msg "$utterance" '{inputs:[{userMessage:$msg}]}')
resp=$(sf api request rest -o "$ORG" \
  "/services/data/v66.0/actions/custom/generateAiAgentResponse/$AGENT" \
  -X POST -H "Content-Type:application/json" -b "-" <<<"$body")

SESSION=$(jq -r '.[0].outputValues.sessionId' <<<"$resp")
text=$(jq -r '.[0].outputValues.agentResponse | fromjson | .value // .' <<<"$resp")
ok=$(jq -r '.[0].isSuccess' <<<"$resp")
err=$(jq -r '.[0].errors // empty' <<<"$resp")

# Turn 2 (and subsequent) — pass sessionId back
body=$(jq -n --arg msg "$next" --arg sid "$SESSION" \
  '{inputs:[{userMessage:$msg, sessionId:$sid}]}')
resp=$(sf api request rest -o "$ORG" \
  "/services/data/v66.0/actions/custom/generateAiAgentResponse/$AGENT" \
  -X POST -H "Content-Type:application/json" -b "-" <<<"$body")
```

`agentResponse` is wrapped as `{"type":"Text","value":"..."}` — unwrap to `.value` for judging. If unwrap fails, fall back to the raw string (some action errors come through unwrapped).

### Running the full suite

Each test (across both `demo-story.yaml` and `prompt-regression.yaml`) is independent (its own session). Run them in parallel:

```bash
mkdir -p /tmp/ae && rm -f /tmp/ae/*.txt
# Iterate spec.tests[]: for each test, drive its turns over REST,
# write the in-memory transcript to /tmp/ae/<name>.txt as it goes.
# Background each test with & and `wait` for all to finish.
```

Then walk each transcript and grade against the corresponding `expect` strings. Print:

```
CallRestApi              PASS  Task record returned with subject Call Burlington.
QueryRecordsWithSoql     FAIL  Listed 5 opportunities but didn't single out Acme.
SalesRepMondayMorning    PASS  All 7 turns met expectations.
```

Surface `errors` from the response verbatim — the JSON is descriptive.

### Prerequisites

Agent must be `Active`. Deploys of `genAiPlugin` / `genAiFunction` / `bot` metadata routinely flip the bot to `Inactive`. Always check before running:

```bash
sf data query -o my-org-butler_DEV -q "SELECT DeveloperName, Status FROM BotVersion WHERE BotDefinitionId IN (SELECT Id FROM BotDefinition WHERE DeveloperName = 'MyOrgButler')" --json
```

Re-activate with `sf agent activate -o my-org-butler_DEV -n MyOrgButler`.

### Common failures

- **`isSuccess: false` with `errors`**: agent invocation failed inside the planner. Surface the error string — it usually names the action that errored.
- **Generic reply / topic not invoked**: bot is `Inactive` or the planner bundle is stale. Re-activate; refresh planner bundle topics.
- **`NOT_FOUND` on the action URL**: Agentforce isn't enabled in the org, or `<AgentApiName>` doesn't match `BotDefinition.DeveloperName`.

---

## Key differences

| Capability                | Testing Center          | REST agent tests                |
|---------------------------|-------------------------|---------------------------------|
| Multi-turn conversations  | Fake (injected history) | Real (one in-org session)       |
| Per-turn assertions       | Final turn only         | Every turn                      |
| Topic / action assertions | Yes                     | No (planner trace not emitted)  |
| Response quality judge    | SF built-in, opaque     | Claude (this conversation)      |
| External dependencies     | None                    | None (uses CLI org auth)        |
| Test format               | XML, deploy to test     | One YAML, run from CLI          |
