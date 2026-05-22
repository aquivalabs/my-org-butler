# My Org Butler — Project Rules

## AI Agent (CI)

When running as the `SF Ticket to PR` GitHub Actions workflow, follow the `salesforce-ai-tools:sf-ticket-to-pr` plugin skill for the full runbook. The skill is generic; the project-specific rules below override it where they conflict.

**Refuse-list additions for this repo.** Data Cloud, External Services, or Named Credentials changes — namespaced scratch orgs hit known platform bugs here (see memory). Refuse those, do not try.

**Namespace strip-deploy-restore.** This repo is namespaced (`aquiva_os__`) but the scratch org is namespaceless. Before redeploying a changed file, strip the namespace, deploy, then restore the working tree:

    sed -i 's/aquiva_os__//g' force-app/main/default/classes/<File>.cls && \
      sf project deploy start --source-dir force-app/main/default/classes/<File>.cls --concise; \
      git checkout -- force-app/main/default/classes/<File>.cls

**Agentforce metadata.** For deploys that touch `genAiFunctions/`, `genAiPromptTemplates/`, `genAiPlugins/`, `genAiPlannerBundles/`, or `bots/`, follow the `salesforce-ai-tools:agentforce-deploy` plugin skill — Salesforce CLI has known gaps here.

## Coding Philosophy

1. **Readability over cleverness** — Code is read far more than written. Optimize for the reader.
2. **Simplicity over sophistication** — No deep package hierarchies, no enterprise patterns. Flat folders, simple names, minimal abstraction.
3. **Explicit over implicit** — When you deviate from defaults, say why. No magic.
4. **Tests as documentation** — Class + method name reads as a sentence describing behavior.
5. **Leverage existing solutions** — Don't reinvent. Use the libraries already in the project.

Salesforce/Apex specifics live in [.claude/rules/salesforce/coding-standards.md](.claude/rules/salesforce/coding-standards.md). After creating or modifying `.cls`, `.trigger`, or `*-meta.xml` files, run `/sf-code-analyzer` on the changed files and fix any new findings before declaring done. Pre-existing findings on lines you did not touch are out of scope.

## Working Style

- **Don't guess on expensive operations.** When unsure about a config value, feature name, or setting — verify against a known-working reference (other branch, docs) before running something that takes minutes to fail (scratch-org creation, large deploys).
- **Fail loud, never silently.** "Completed", "tests pass", "feature works" are wrong if anything was skipped or any edge case wasn't verified. Surface uncertainty by default — partial success is not success.
- **Surface conflicts, don't average them.** If two existing patterns in the codebase contradict, pick one (more recent / more tested), say why, and flag the other. Don't write code that satisfies both — blended code is the worst code.

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

Parsing + retry logic is in the `eval` command of the `salesforce-ai-tools:agentforce` plugin skill.

## Multi-turn agent tests (REST)

Two YAMLs in `agent-eval/`:

- `demo-story.yaml` — the conference demo, automated. One coherent multi-turn conversation (`SalesRepMondayMorning`) chaining actions into a sales-rep workflow.
- `prompt-regression.yaml` — smoke tests that exercise specific prompt templates (`ConsolidateMemory`, `AnswerFromFile`) through the agent.

Per-action regression already lives in the Testing Center XML; this layer covers what single-turn can't capture (multi-turn flows, prompt-template behaviors that need a real session).

Driven over the in-org Invocable Action endpoint (`/services/data/vXX.X/actions/custom/generateAiAgentResponse/MyOrgButler`) via `sf api request rest`, judged by Claude in-memory against each `expect`. No Apex template, no transcript-record persistence, no Connected App.

Runner details + spec format are in the `eval` command of the `salesforce-ai-tools:agentforce` plugin skill, under "Multi-turn agent tests (REST)".

## LLM Judge

Rubrics assert on **specific data** (filenames, dollar amounts, counts) — not vague "confirms it worked." Testing Center uses Salesforce's built-in evaluator (judge model is opaque). Multi-turn REST tests use Claude (this conversation).

## Current State (2026-04-30)

Testing Center suite: single `Regression` definition with 14 cases; 2 parallel passes complete in a few minutes without tripping the 10-job concurrency cap.

**Main open issue: [#56](https://github.com/aquivalabs/my-org-butler/issues/56)** — test-suite shape / flakiness tracker. Data Cloud routing (SearchDataLibrary, QueryDataCloud) remains the one intermittent case. Done criteria: multiple consecutive clean runs.
