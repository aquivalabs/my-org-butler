# /agentforce eval — Regression Testing

Run regression tests against agents and prompt templates.

Three test systems, distinct purposes:
- **Testing Center** — per-action single-turn regression (on-platform, `sf agent test run`)
- **Apex-based agent tests** — multi-turn conversations against a deployed agent, judged by Claude
- **Prompt template tests** — single-prompt evals via Promptfoo + the Generations API (`npx promptfoo@latest eval`)

---

## Testing Center

### Structure

One XML per action in `agent-eval/`. Filename = `<ActionName>.aiEvaluationDefinition-meta.xml`. API name inside `<name>` matches the filename stem. Each file has exactly one `testCase`.

Why one-per-file: lets us run all tests in parallel with one `sf agent test run` invocation per file — a full suite completes in ~2 min instead of 5–10 min serial.

### Running in parallel

`sf agent test run --wait` has two issues: it's serial (one at a time) and the CLI polling crashes with `TestPollFailed: no constant with the specified name: RETRY` on ~20% of runs. The test completes server-side even when the CLI dies. Handle both by launching jobs in the background, capturing JSON output to `/tmp/`, and parsing what landed.

```bash
# Run all tests in parallel
mkdir -p /tmp/ae && rm -f /tmp/ae/*.json
for f in agent-eval/*.aiEvaluationDefinition-meta.xml; do
  name=$(basename "$f" .aiEvaluationDefinition-meta.xml)
  (sf agent test run --api-name "$name" --wait 10 --result-format json > "/tmp/ae/$name.json" 2>&1) &
done
wait
```

`--wait 10` caps each polling loop at 10 min. The `&` backgrounds each invocation; `wait` blocks until all finish.

### Consolidating results (handles the polling bug)

The CLI captures JSON even when the polling crashes mid-way — the last `{` in the file marks the start of the result document. Python parses that robustly:

```bash
python3 <<'PY'
import os, re, json
passed = failed = crashed = 0
failures = []
for fn in sorted(os.listdir('/tmp/ae')):
    if not fn.endswith('.json'): continue
    name = fn[:-5]
    raw = open(f'/tmp/ae/{fn}').read()
    matches = list(re.finditer(r'\n\{\n', raw))
    if not matches:
        crashed += 1; failures.append((name, 'CLI polling crash — check Testing Center UI'))
        continue
    start = matches[-1].start() + 1
    try:
        d = json.loads(raw[start:])
    except Exception as e:
        crashed += 1; failures.append((name, f'JSON parse error: {e}')); continue
    # walk for testResults
    def find(o):
        if isinstance(o, dict):
            if 'testResults' in o: return o['testResults']
            for v in o.values():
                r = find(v)
                if r: return r
        if isinstance(o, list):
            for v in o:
                r = find(v)
                if r: return r
    results = find(d) or []
    statuses = {r['name']: r['result'] for r in results}
    ok = all(s == 'PASS' for s in statuses.values())
    if ok:
        passed += 1
    else:
        failed += 1
        expl = ' '.join(f'{k[:6]}={v}' for k,v in statuses.items())
        failures.append((name, expl))
print(f'PASS {passed}  FAIL {failed}  CRASH {crashed}')
for n, msg in failures: print(f'  {n}: {msg}')
PY
```

### Retrying crashes

Polling crashes are CLI-only; the test finished server-side. Two strategies:

1. **Re-run only the crashed ones** (fast): after the first pass, re-invoke `sf agent test run --api-name <name>` for each crashed name. 2nd attempt usually succeeds because polling hits at a different server state.
2. **Check the UI**: Setup → Agentforce → Testing Center → the eval run has the real result.

Prefer strategy 1 in scripts; strategy 2 when debugging.

### Deploy

`sf project deploy start --source-dir agent-eval --concise`

### What each test probes

Each file has:
- `topic_assertion` — agent routes to MyOrgButler topic
- `actions_assertion` — agent calls the expected action sequence
- `bot_response_rating` — LLM judge grades response content

Goal: 100% on all three, across all files.

---

## Multi-turn agent tests (REST)

All scenarios live in **one** YAML: `agent-eval/regression.test.yaml`. Each entry has plain-English `expect` criteria. Claude drives the agent over the in-org Invocable Action REST endpoint, keeps the transcript in memory, and judges each turn against `expect`.

Why this endpoint: the `generateAiAgentResponse` invocable action is exposed at `/services/data/vXX.X/actions/custom/generateAiAgentResponse/<AgentApiName>`. `sf api request rest` hits it with the CLI's existing org auth — no Connected App, no JWT, no api.salesforce.com. Returns `sessionId` + `agentResponse` directly as JSON. Multi-turn works by passing the `sessionId` back into the next call.

What it can't observe: planner trace (which topic routed, which actions invoked). That data lives in Data Cloud DLM tables; the `ConversationDefinitionEventLog` only captures dialog-level events with sensitive fields redacted. Topic/action assertions stay in Testing Center.

### Spec format

```yaml
agent: MyOrgButler

tests:
  # Single-turn shortcut
  - name: CallRestApi
    say: 'use the REST API to create a new Task with Subject "Call Burlington"'
    expect: Confirms a Task record was created with subject containing Call Burlington

  # Multi-turn — all turns share one agent session
  - name: SalesRepMondayMorning
    description: Sales rep Monday-morning workflow
    turns:
      - say: which opportunity should I work on next?
        expect: Recommends the Acme Q1 Expansion Deal as top priority
      - say: create a task to call Acme about the discount
        expect: Confirms a task was created on the Acme opportunity, mentions VP approval or discount
```

`expect` is plain English — Claude grades the agent's reply against it. No substring matching. Per-test `name` should match the action being probed; it's also how the runner reports pass/fail.

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

Each test in `regression.test.yaml` is independent (its own session). Run them in parallel:

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

## Prompt template tests

Single-prompt evals via Promptfoo + the Einstein Generations API.

```bash
cd agent-eval && npx promptfoo@latest eval -c prompt-regression.yaml --env-file .env --output /tmp/prompt-results.json
```

### Reading results

```bash
python3 -c "
import json
data = json.load(open('/tmp/prompt-results.json'))
results = data.get('results', {}).get('results', [])
for r in results:
    desc = r.get('description', r.get('vars', {}).get('promptTemplateName', '?'))[:60]
    passed = r.get('success', False)
    if not passed:
        failures = [a.get('reason','?') for a in r.get('gradingResult',{}).get('componentResults',[]) if not a.get('pass')]
        print(f'FAIL: {desc}')
        for f in failures:
            print(f'      {f[:120]}')
    else:
        print(f'PASS: {desc}')
"
```

### Test format

Each test specifies `promptTemplateName` and the template's input variables. For SObject inputs, declare the type via `sobjectInputs`.

```yaml
providers:
  - id: "file://../.claude/skills/agentforce/providers/sf-generations-api.mjs"
    label: "Einstein Generations API"

tests:
  - description: "Summarize attached document"
    vars:
      promptTemplateName: AnswerFromFile
      userQuestion: "Give me a TL;DR of this document"
      file: "${CONTENT_DOCUMENT_ID}"
      sobjectInputs:
        file: "SOBJECT://ContentDocument"
    assert:
      - type: javascript
        value: "output.success === true"
      - type: llm-rubric
        value: "Provides a concise summary of the document content"
```

---

## Key differences

| Capability                | Testing Center          | REST agent tests                | Prompt template tests          |
|---------------------------|-------------------------|---------------------------------|--------------------------------|
| Multi-turn conversations  | Fake (injected history) | Real (one in-org session)       | N/A — single prompt            |
| Per-turn assertions       | Final turn only         | Every turn                      | N/A                            |
| Topic / action assertions | Yes                     | No (planner trace not emitted)  | N/A                            |
| Response quality judge    | SF built-in, opaque     | Claude (this conversation)      | Your choice (gpt-4o, etc.)     |
| External dependencies     | None                    | None (uses CLI org auth)        | Node.js, Promptfoo, OpenAI key |
| Test format               | XML, deploy to test     | One YAML, run from CLI          | YAML, run from CLI             |
