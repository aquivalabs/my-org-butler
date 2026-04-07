# /agentforce eval — Regression Testing

Run regression tests against agents and prompt templates.

Two test systems, distinct purposes:
- **Testing Center** — per-action single-turn regression (on-platform, `sf agent test run`)
- **Promptfoo** — multi-turn conversations and prompt template tests (CLI, `npx promptfoo@latest eval`)

---

## Testing Center

### Running

ALWAYS use `--json`. NEVER use `--result-format human` — the human output is full of ANSI escape codes and progress spinners that break all parsing.

```bash
sf agent test run --api-name Regression_Test --wait 15 --json 2>&1 > /tmp/tc-results.json
```

### Reading results

Parse the JSON output. The file may have a non-JSON prefix (shell warnings) — skip to the first `{`.

```bash
python3 -c "
import json
with open('/tmp/tc-results.json') as f:
    content = f.read()
    d = json.loads(content[content.index('{'):])
r = d.get('result', {})
cases = r.get('testCases', [])
tp = ap = op = 0
for c in cases:
    num = c.get('testNumber', '?')
    utt = c.get('inputs', {}).get('utterance', '')[:70]
    results = {tr.get('name'): tr for tr in c.get('testResults', [])}
    t = results.get('topic_assertion', {})
    a = results.get('actions_assertion', {})
    o = results.get('output_validation', {}) or results.get('bot_response_rating', {})
    tr_ = t.get('result', '?')
    ar_ = a.get('result', '?')
    or_ = o.get('result', '?')
    if tr_ == 'PASS': tp += 1
    if ar_ == 'PASS': ap += 1
    if or_ == 'PASS': op += 1
    ok = tr_ == 'PASS' and ar_ == 'PASS' and or_ == 'PASS'
    print(f'{\"PASS\" if ok else \"FAIL\"} #{num} T:{tr_} A:{ar_} O:{or_} | {utt}')
    if ar_ != 'PASS' and a.get('actualValue'):
        print(f'   Expected: {a.get(\"expectedValue\",\"\")}')
        print(f'   Actual:   {a.get(\"actualValue\",\"\")}')
    if or_ != 'PASS' and o.get('actualValue'):
        print(f'   Outcome: {str(o.get(\"actualValue\",\"\"))[:200]}')
n = len(cases) or 1
print(f'\nTopic: {tp}/{n} ({100*tp//n}%) | Action: {ap}/{n} ({100*ap//n}%) | Outcome: {op}/{n} ({100*op//n}%)')
"
```

### Test file

`regressions/aiEvaluationDefinitions/Regression_Test.aiEvaluationDefinition-meta.xml`

Deploy with: `sf project deploy start --source-dir regressions --concise`

### What Testing Center tests

One test per action. Single-turn only. Each test has three expectations:
- `topic_assertion` — agent routes to the right topic
- `actions_assertion` — agent calls the expected action(s)
- `bot_response_rating` — LLM judge evaluates the response content

Goal: 100% on all three.

---

## Promptfoo

### Running

Test files live in `regressions/promptfoo/`. Always use `--output` to capture structured results, then report failures inline — never rerun just to see what failed.

```bash
# Demo story (multi-turn)
cd regressions/promptfoo && npx promptfoo@latest eval -c demo-story.yaml --env-file .env --output /tmp/demo-results.json

# Multi-turn regression
cd regressions/promptfoo && npx promptfoo@latest eval -c regression.yaml --env-file .env --output /tmp/regression-results.json

# Prompt template regression
cd regressions/promptfoo && npx promptfoo@latest eval -c prompt-regression.yaml --env-file .env --output /tmp/prompt-results.json
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
  - id: "file://../../.claude/skills/agentforce/providers/sf-agent-api.mjs"
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
  - id: "file://../../.claude/skills/agentforce/providers/sf-generations-api.mjs"
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
