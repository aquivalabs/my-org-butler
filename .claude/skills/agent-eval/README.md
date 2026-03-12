# Agent Eval

Test Agentforce agents with real multi-turn conversations using [Promptfoo](https://promptfoo.dev).

## The problem

Agentforce Testing Center fakes multi-turn. It injects hardcoded conversation history — "pretend the agent said this." The agent never actually responded. There's no real session state.

This matters because real conversations build on real context. When a user says "tell me more about the first one," that only works if the agent actually listed something. When a user stores a preference, it only works if the agent actually saved it. Testing Center hides these bugs.

## The fix

Describe conversations naturally. Each turn is a real API call with its own assertion. The provider maintains session state automatically via `conversationId`:

```yaml
tests:
  # --- Store a preference, then verify it sticks ---

  - description: "User sets a display preference"
    vars:
      utterance: "From now on, always sort my opportunities by close date"
      conversationId: preference
    assert:
      - type: llm-rubric
        value: "Confirms it will remember the sorting preference"

  - description: "User checks if preference was applied"
    vars:
      utterance: "Show me my opportunities"
      conversationId: preference
    assert:
      - type: llm-rubric
        value: "Shows opportunities sorted by close date, soonest first"
```

No fake agent responses. No JSON blobs. Just what the user says and what you expect back. Turns sharing a `conversationId` are part of the same real conversation.

## What it found

The multi-turn tests exposed a real agent bug: the agent loses conversational context for pronoun resolution. "Which of those is the largest?" gets "Could you clarify which deals?" — the agent forgot what it just listed. Testing Center hides this by injecting the list as fake history.

## Setup

Create `agent-eval/.env` (gitignored):

```env
AGENT_NAME=YourAgentName
API_VERSION=v65.0
OPENAI_API_KEY=sk-...
```

Run:

```bash
cd agent-eval
npx promptfoo@latest eval -c regression.yaml --env-file .env
npx promptfoo@latest view
```

## Claude skill

This repo includes a Claude Code skill at `.claude/skills/agent-eval/` that can:

- Write multi-turn and single-turn tests
- Convert Testing Center XML to Promptfoo YAML
- Run evaluations

Use it with `/agent-eval run` or `/agent-eval port`.
