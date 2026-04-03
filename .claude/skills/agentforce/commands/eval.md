# /agentforce eval — Regression Testing

Run regression tests against agents and prompt templates using Promptfoo.

## Why this exists

Agentforce Testing Center fakes multi-turn conversations — it injects hardcoded history, the agent never actually responds. Prompt templates have no built-in regression testing at all.

This command runs real API calls. Every turn gets its own assertion.

## Test format

### Agent tests (multi-turn)

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

### Prompt template tests

Each test specifies `promptTemplateName` and the template's input variables. For SObject inputs, declare the type via `sobjectInputs`.

```yaml
providers:
  - id: "file://../.claude/skills/agentforce/providers/sf-generations-api.mjs"
    label: "Einstein Generations API"

tests:
  - description: "Merge memories preserving specificity"
    vars:
      promptTemplateName: ConsolidateMemory
      consolidatedMemory: "User prefers tables with Amount, Stage, CloseDate"
      newMemory: "User also wants Industry field when showing accounts"
    assert:
      - type: javascript
        value: "output.success === true"
      - type: llm-rubric
        value: "Preserves specific field names and object contexts"

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

## Running tests

Test files live in `regressions/promptfoo/`. Always use `--output` to capture structured results, then report failures inline — never rerun just to see what failed.

```bash
# Agent regression
cd regressions/promptfoo && npx promptfoo@latest eval -c agent-regression.yaml --env-file .env --output /tmp/agent-results.json

# Prompt template regression
cd regressions/promptfoo && npx promptfoo@latest eval -c prompt-regression.yaml --env-file .env --output /tmp/prompt-results.json
```

## Reading results

After every run, parse the JSON output to report pass/fail per test with failure reasons. Never ask to rerun.

```bash
python3 -c "
import json
data = json.load(open('/tmp/agent-results.json'))
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

## Key differences from Testing Center

| Capability               | Testing Center          | Promptfoo                           |
|--------------------------|-------------------------|-------------------------------------|
| Multi-turn conversations | Fake (injected history) | Real (replayed API calls)           |
| Per-turn assertions      | Final turn only         | Every turn                          |
| Prompt template testing  | Not supported           | Via Generations API provider        |
| Response quality judge   | SF built-in, opaque     | Your choice (o3-mini, Claude, etc.) |
| Topic/action assertions  | Yes                     | No (runtime internal)               |
| Test format              | XML, deploy to test     | YAML, run from CLI                  |
