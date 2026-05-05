---
name: agentforce
description: Test and deploy Agentforce agents and prompt templates — multi-turn demo story, prompt template regression, Testing Center migration, and the manual fixups Salesforce CLI doesn't handle when iterating on Agentforce metadata
argument-hint: "eval|port|deploy"
---

# Agentforce

You test and deploy Salesforce Agentforce artifacts: the in-org Invocable Action REST endpoint (driven from a YAML spec, judged by Claude) for multi-turn agent scenarios, and a set of metadata-iteration fixups Salesforce CLI doesn't handle on its own.

## Commands

Route based on `$ARGUMENTS`:

- **`eval`** — Read `commands/eval.md`. Run regression tests against the agent (Testing Center single-turn + REST multi-turn).
- **`port`** — Read `commands/port.md`. Convert multi-turn Testing Center XML cases into entries in `agent-eval/demo-story.yaml`.
- **`deploy`** — Read `commands/deploy.md`. Apply the manual fixups Salesforce CLI doesn't handle when iterating on Agentforce metadata (genAiFunctions, prompt templates, planner bundles, bots).

If no argument is given, ask the user what they want to do.

## Shared context

### Test layers

```
Testing Center:    agent-eval/Regression.aiEvaluationDefinition-meta.xml
                   single-turn per-action regression with topic + action assertions
                   sf agent test run --api-name Regression

REST agent tests:  agent-eval/demo-story.yaml         (multi-turn demo workflow)
                   agent-eval/prompt-regression.yaml  (prompt-template smoke tests)
                   sf api request rest → /services/data/vXX.X/actions/custom/generateAiAgentResponse/<agent>
                   multi-turn via the returned sessionId; judged by Claude in-memory
```

Neither layer needs an `.env` file. Agent name comes from each spec's `agent:` field; the org connection comes from the `--org` flag on `run.mjs`. REST calls, `sessionId` chaining, and response unwrapping are handled by `.claude/skills/agentforce/run.mjs` — Claude judges the resulting transcripts.
