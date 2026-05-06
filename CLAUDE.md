# My Org Butler — Project Rules

## AI Agent (CI)

When running as the `SF Ticket to PR` GitHub Actions workflow, follow `.claude/skills/sf-ticket-to-pr/SKILL.md` for the full runbook. The rules below still apply.

## Deploying

Never run `sf project deploy start --source-dir force-app`. The scratch org is namespaceless but some metadata files contain namespace references, so a full deploy always fails. Always deploy only the specific files you changed:

```
sf project deploy start \
  --source-dir force-app/main/default/classes/Foo.cls \
  --source-dir force-app/main/default/classes/Bar.cls
```

## Testing Strategy

Everything lives in `agent-eval/`. Two test layers:

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

## Multi-turn agent tests (REST)

Two YAMLs in `agent-eval/`:

- `demo-story.yaml` — the conference demo, automated. One coherent multi-turn conversation (`SalesRepMondayMorning`) chaining actions into a sales-rep workflow.
- `prompt-regression.yaml` — smoke tests that exercise specific prompt templates (`ConsolidateMemory`, `AnswerFromFile`) through the agent.

Per-action regression already lives in the Testing Center XML; this layer covers what single-turn can't capture (multi-turn flows, prompt-template behaviors that need a real session).

Driven over the in-org Invocable Action endpoint (`/services/data/vXX.X/actions/custom/generateAiAgentResponse/MyOrgButler`) via `sf api request rest`, judged by Claude in-memory against each `expect`. No Apex template, no transcript-record persistence, no Connected App.

Runner details + spec format in `.claude/skills/agentforce/commands/eval.md` → "Multi-turn agent tests (REST)".

## LLM Judge

Rubrics assert on **specific data** (filenames, dollar amounts, counts) — not vague "confirms it worked." Testing Center uses Salesforce's built-in evaluator (judge model is opaque). Multi-turn REST tests use Claude (this conversation).

## Current State (2026-04-30)

Testing Center suite: single `Regression` definition with 14 cases; 2 parallel passes complete in a few minutes without tripping the 10-job concurrency cap.

**Main open issue: [#56](https://github.com/aquivalabs/my-org-butler/issues/56)** — test-suite shape / flakiness tracker. Data Cloud routing (SearchDataLibrary, QueryDataCloud) remains the one intermittent case. Done criteria: multiple consecutive clean runs.
