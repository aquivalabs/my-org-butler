# Deploying

Never run `sf project deploy start --source-dir force-app`. The scratch org is namespaceless but some metadata files contain namespace references, so a full deploy always fails. Always deploy only the specific files you changed:

```
sf project deploy start \
  --source-dir force-app/main/default/classes/Foo.cls \
  --source-dir force-app/main/default/classes/Bar.cls
```

# Testing Strategy

Three test layers, zero overlap. Every action is tested exactly once.

## Testing Center (single-turn)
`regressions/aiEvaluationDefinitions/Regression_Test.aiEvaluationDefinition-meta.xml`

For actions that work in a single request/response. Runs on-platform.
```
sf agent test run --api-name Regression_Test --wait 15 --result-format human
```

## Promptfoo Demo Story (multi-turn)
`regressions/promptfoo/demo-story.yaml`

Multi-turn conversations that chain actions into coherent user workflows. This IS the conference demo, automated as a test.
```
cd regressions/promptfoo && npx promptfoo@latest eval -c demo-story.yaml --env-file .env
```

## Promptfoo Prompt Tests (template isolation)
`agentforce-eval/prompt-regression.yaml`

Smoke test for the prompt template provider. Calls the Generations REST API directly, no agent involved.
```
cd agentforce-eval && npx promptfoo@latest eval -c prompt-regression.yaml --env-file .env
```

## LLM Judge
All rubrics assert on **specific data** (dollar amounts, field names, object names, cron expressions) — not vague "confirms it worked" statements. Judge model: `gpt-4o`.

## Running Tests
Run independent test suites in parallel using background tasks or subagents. Never run them sequentially when they don't depend on each other. Show results in one pass — never rerun to analyze, never use Python to parse CLI output.

## .env
Only two values: `OPENAI_API_KEY` (LLM judge) and `CONTENT_DOCUMENT_ID` (sample file). Agent name and API version are hardcoded in the YAML.
