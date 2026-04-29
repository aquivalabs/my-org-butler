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

One `agent-eval/Regression.aiEvaluationDefinition-meta.xml` with 14 `testCase` blocks — one per action. Runs on-platform via `sf agent test run --api-name Regression`. This is the only layer that asserts on topic and action routing (planner trace).

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

## Multi-turn agent regression (REST)

`agent-eval/regression.test.yaml` — single YAML, all multi-turn scenarios. Driven over the in-org Invocable Action endpoint (`/services/data/vXX.X/actions/custom/generateAiAgentResponse/MyOrgButler`) via `sf api request rest`, judged by Claude in-memory against each `expect`. No Apex template, no transcript-record persistence, no Connected App. Includes the conference demo (`SalesRepMondayMorning`) as a multi-turn entry.

Runner details + spec format in `.claude/skills/agentforce/commands/eval.md` → "Multi-turn agent tests (REST)".

## Promptfoo Prompt Tests (template isolation)

`agent-eval/prompt-regression.yaml` — smoke test for the prompt template provider via Generations REST API.

```
cd agent-eval && npx promptfoo@latest eval -c prompt-regression.yaml --env-file .env
```

## LLM Judge

Rubrics assert on **specific data** (filenames, dollar amounts, counts) — not vague "confirms it worked." Testing Center + Promptfoo use `gpt-4o-mini`. Multi-turn REST tests use Claude (this conversation).

## .env

Two values: `OPENAI_API_KEY` (LLM judge for Testing Center / Promptfoo) and `CONTENT_DOCUMENT_ID` (sample file).

# Current State (2026-04-29)

Testing Center suite is a single `Regression` definition with 14 cases. Parallel run of 2 passes completes in a few minutes without tripping the 10-job concurrency cap.

Multi-turn agent tests migrated from anonymous Apex (with sObject-persisted transcript) to direct REST (`sf api request rest` against the `generateAiAgentResponse` invocable action). All 14 single-turn tests + the 7-turn `SalesRepMondayMorning` demo now live in one `agent-eval/regression.test.yaml`. Apex template and per-test YAML files are gone.

**Main open issue: [#56](https://github.com/aquivalabs/my-org-butler/issues/56)** — test-suite shape / flakiness tracker. Data Cloud routing (SearchDataLibrary, QueryDataCloud) remains the one intermittent case. Done criteria: multiple consecutive clean runs.
