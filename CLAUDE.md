# Deploying

Never run `sf project deploy start --source-dir force-app`. The scratch org is namespaceless but some metadata files contain namespace references, so a full deploy always fails. Always deploy only the specific files you changed:

```
sf project deploy start \
  --source-dir force-app/main/default/classes/Foo.cls \
  --source-dir force-app/main/default/classes/Bar.cls
```

# Testing Strategy

Everything lives in `agent-eval/`. Three test layers, zero overlap:

## Testing Center (single-turn regression)

One `agent-eval/Regression.aiEvaluationDefinition-meta.xml` with 14 `testCase` blocks — one per action. Runs on-platform via `sf agent test run --api-name Regression`.

Salesforce caps concurrent test jobs at **10 per 10-hour window** ([Trailhead](https://trailhead.salesforce.com/content/learn/modules/agentforce-agent-testing/trust-your-agents)). Launching 14 per-action tests in parallel hit that cap and threw `TestStartFailed: Too many inflight evaluations`, so we use a single definition with multiple cases instead.

Run 2 passes in parallel:

```bash
mkdir -p /tmp/ae && rm -f /tmp/ae/*.json
for i in 1 2; do
  (sf agent test run --api-name Regression --wait 30 --result-format json > "/tmp/ae/Regression_run$i.json" 2>&1) &
done
wait
```

Parsing + retry logic is in `.claude/skills/agentforce/commands/eval.md`.

## Promptfoo Demo Story (multi-turn)

`agent-eval/demo-story.yaml` — the conference demo automated. Multi-turn conversation chaining actions into a sales-rep workflow.

```
cd agent-eval && npx promptfoo@latest eval -c demo-story.yaml --env-file .env
```

## Promptfoo Prompt Tests (template isolation)

`agent-eval/prompt-regression.yaml` — smoke test for the prompt template provider via Generations REST API.

```
cd agent-eval && npx promptfoo@latest eval -c prompt-regression.yaml --env-file .env
```

## LLM Judge

Rubrics assert on **specific data** (filenames, dollar amounts, counts) — not vague "confirms it worked." Judge model: `gpt-4o-mini`.

## .env

Two values: `OPENAI_API_KEY` (LLM judge) and `CONTENT_DOCUMENT_ID` (sample file).

# Current State (2026-04-21)

Testing Center suite is a single `Regression` definition with 14 cases. Parallel run of 2 passes completes in a few minutes without tripping the 10-job concurrency cap.

**Main open issue: [#56](https://github.com/aquivalabs/my-org-butler/issues/56)** — test-suite shape / flakiness tracker. Data Cloud routing (SearchDataLibrary, QueryDataCloud) remains the one intermittent case. Done criteria: multiple consecutive clean runs.
