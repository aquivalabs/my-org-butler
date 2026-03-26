# Agentforce Eval

Regression-test Agentforce agents and prompt templates using [Promptfoo](https://promptfoo.dev).

## What this skill solves

1. **Testing Center fakes conversations.** Its `conversationHistory` lets you script both sides. The agent never actually responds — it's a mockup, not a test.
2. **Prompt templates have zero regression testing.** They run inside Flows, Apex, and agent actions — LLM calls just as likely to regress as agent conversations.

## Real agent conversations

Multi-turn with real session state. The agent actually responds at each turn:

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

## Prompt template smoke tests

Assert on output quality and safety scores:

```yaml
tests:
  - vars:
      promptTemplateName: ConsolidateMemory
      consolidatedMemory: "Sort by Amount descending"
      newMemory: "Sort by CloseDate ascending"
    assert:
      - type: llm-rubric
        value: "Sorts by CloseDate, not Amount"
```

## Commands

- `/agentforce-eval run` — run regression tests
- `/agentforce-eval port` — convert Testing Center XML to Promptfoo YAML
