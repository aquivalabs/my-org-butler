# /agentforce eval — Regression Testing

Run regression tests against agents and prompt templates.

Two test systems, distinct purposes:
- **Testing Center** — per-action single-turn regression (on-platform, `sf agent test run`)
- **Promptfoo** — multi-turn conversations and prompt template tests (CLI, `npx promptfoo@latest eval`)

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

## Promptfoo

### Running

Test files live in `agent-eval/`. Always use `--output` to capture structured results, then report failures inline — never rerun just to see what failed.

```bash
# Demo story (multi-turn)
cd agent-eval && npx promptfoo@latest eval -c demo-story.yaml --env-file .env --output /tmp/demo-results.json

# Multi-turn regression
cd agent-eval && npx promptfoo@latest eval -c regression.yaml --env-file .env --output /tmp/regression-results.json

# Prompt template regression
cd agent-eval && npx promptfoo@latest eval -c prompt-regression.yaml --env-file .env --output /tmp/prompt-results.json
```

### Reading results

```bash
python3 -c "
import json
data = json.load(open('/tmp/demo-results.json'))
results = data.get('results', {}).get('results', [])
for r in results:
    desc = r.get('description', r.get('vars', {}).get('utterance', '?'))[:60]
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

#### Agent tests (multi-turn)

Turns sharing a `conversationId` are part of the same real conversation — the provider maintains session state automatically.

```yaml
providers:
  - id: "file://../.claude/skills/agentforce/providers/sf-agent-api.mjs"
    label: "MyOrgButler"

evaluateOptions:
  maxConcurrency: 1    # required — turns must run in order

tests:
  - description: "Set a display preference"
    vars:
      utterance: "From now on, always sort my opportunities by close date"
      conversationId: preference
    assert:
      - type: javascript
        value: "output.success === true"
      - type: llm-rubric
        value: "Confirms it will remember the sorting preference"

  - description: "Check if preference was applied"
    vars:
      utterance: "Show me my opportunities"
      conversationId: preference
    assert:
      - type: javascript
        value: "output.success === true"
      - type: llm-rubric
        value: "Shows opportunities sorted by close date, soonest first"
```

#### Prompt template tests

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

| Capability               | Testing Center          | Promptfoo                           |
|--------------------------|-------------------------|-------------------------------------|
| Multi-turn conversations | Fake (injected history) | Real (replayed API calls)           |
| Per-turn assertions      | Final turn only         | Every turn                          |
| Prompt template testing  | Not supported           | Via Generations API provider        |
| Response quality judge   | SF built-in, opaque     | Your choice (gpt-4o, Claude, etc.)  |
| Topic/action assertions  | Yes                     | No (runtime internal)               |
| Test format              | XML, deploy to test     | YAML, run from CLI                  |
