# /agentforce

Test and optimize Agentforce agents and prompt templates using the open-source [Promptfoo CLI](https://github.com/promptfoo/promptfoo).

## Commands

- `/agentforce eval` — run regression tests against agents and prompt templates
- `/agentforce experiment` — optimize a prompt template by testing model and prompt variants
- `/agentforce port` — convert Testing Center XML tests to Promptfoo YAML

## How it works

Two custom Promptfoo providers call Salesforce REST APIs directly — no custom Apex needed:

- **Agent provider** — real multi-turn conversations via the Agent API
- **Generations provider** — prompt template testing via the Generations API

Test files live in `regressions/promptfoo/`. Experiment variants go in `unpackaged/experiments/`.

## Learnings

The skill accumulates process knowledge in `learnings.md` — deployment gotchas, measurement methodology, tooling tips. Read automatically before every experiment, updated after results.
