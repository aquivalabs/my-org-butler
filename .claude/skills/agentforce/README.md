# /agentforce

Test and optimize Agentforce agents and prompt templates using the open-source [Promptfoo CLI](https://github.com/promptfoo/promptfoo).

## What this skill solves

1. **Testing Center fakes conversations.** Its `conversationHistory` lets you script both sides — the agent never actually responds. No real session state. A mockup, not a test.
2. **Prompt templates have zero regression testing.** They run inside Flows, Apex, and agent actions. LLM calls just as likely to regress as agent conversations. No way to check if output got worse after a change.
3. **Comparing models or prompt variants is manual labor.** Is GPT-4.1 faster than GPT-4o Mini for your template? Edit the XML, deploy, test, edit again, deploy again. Nobody does this systematically.

## Commands

- [`/agentforce eval`](commands/eval.md) — run regression tests against agents and prompt templates
- [`/agentforce experiment`](commands/experiment.md) — optimize a prompt template by testing model and prompt variants
- [`/agentforce port`](commands/port.md) — convert Testing Center XML tests to Promptfoo YAML

## Real agent conversations

Multi-turn with real session state. The agent actually responds at each turn — no scripted history. Powered by the [Agent API provider](providers/sf-agent-api.mjs).

```yaml
tests:
  - description: "List Acme opportunities"
    vars:
      utterance: "Show me all my Acme opportunities"
      conversationId: acme-deals
    assert:
      - type: llm-rubric
        value: "Lists at least three Acme opportunities with amounts"

  - description: "Ask for a recommendation"
    vars:
      utterance: "Which one should I work on next?"
      conversationId: acme-deals
    assert:
      - type: llm-rubric
        value: "Recommends one specific Acme opportunity and explains why"
```

Turns sharing a `conversationId` are part of the same real conversation — the provider maintains session state automatically.

## Prompt template regression tests

Assert on output quality via the [Generations API provider](providers/sf-generations-api.mjs):

```yaml
tests:
  - vars:
      promptTemplateName: ConsolidateMemory
      consolidatedMemory: "Sort by Amount descending"
      newMemory: "Sort by CloseDate ascending"
    assert:
      - type: llm-rubric
        value: "Sorts by CloseDate, not Amount — newer preference wins"
```

## Prompt optimization experiments

Test different models or prompt rewrites against the same assertions. The skill drives the experiment conversationally — no config files to write:

```
You: /agentforce experiment
     optimize ConsolidateMemory for latency

Skill: reads template, proposes 3 models × original content
       → creates variant templates, deploys, tests all
       → presents ranked report with latency data

You: apply #1

Skill: writes winner into original template, offers cleanup
```

The experiment workflow accumulates [process learnings](learnings.md) — deployment gotchas, measurement methodology, tooling tips — making each experiment smarter than the last.

Test files live in `regressions/promptfoo/`. Experiment variants go in `unpackaged/experiments/` temporarily and are cleaned up after applying the winner.
