---
name: agent-eval
description: Evaluate Agentforce agents with Promptfoo — real multi-turn conversations, portable test format, your choice of LLM judge
argument-hint: "run|port"
---

# External Agent Evaluation with Promptfoo

You are an expert at evaluating Salesforce Agentforce agents using [Promptfoo](https://promptfoo.dev). You help users write tests, convert Testing Center tests, and run evaluations.

## Why this exists

Agentforce Testing Center fakes multi-turn conversations. It injects hardcoded history — telling the agent "pretend this conversation already happened." The agent never actually said those things. There is no real session state.

This skill uses Promptfoo to replay real API calls. Each turn hits the agent for real, the agent responds for real, and session state accumulates via `sessionId`. Every turn gets its own assertion.

## How it works

```
Promptfoo CLI → JS Provider → Salesforce Invocable Action API → Agentforce Agent
                (providers/salesforce-agent.mjs)
                POST /services/data/{version}/actions/custom/generateAiAgentResponse/{agent}
```

No custom Apex needed. The provider authenticates via `sf org display` and calls the standard REST API.

## Setup

Users must create `agent-eval/.env` (gitignored) with:

```env
AGENT_NAME=MyAgentName
API_VERSION=v65.0
OPENAI_API_KEY=sk-...
```

- `AGENT_NAME`: the API name of the Agentforce agent (set by the admin when creating it)
- `API_VERSION`: Salesforce API version
- `OPENAI_API_KEY`: for the LLM judge (o3-mini by default, can be changed in the YAML)

The `agent-eval/` directory also needs a `package.json` with `{"private": true, "type": "module"}` for ESM support.

## Test format

### Multi-turn conversations

Describe conversations naturally. Each turn is a separate test case. Turns sharing a `conversationId` are part of the same real conversation — the provider maintains session state automatically.

```yaml
evaluateOptions:
  maxConcurrency: 1    # required for multi-turn — turns must run in order

tests:
  # --- Store a preference, then verify it sticks ---

  - description: "User sets a display preference"
    vars:
      utterance: "From now on, always sort my opportunities by close date"
      conversationId: preference
    assert:
      - type: javascript
        value: "output.success === true"
      - type: llm-rubric
        value: "Confirms it will remember the sorting preference"

  - description: "User checks if preference was applied"
    vars:
      utterance: "Show me my opportunities"
      conversationId: preference
    assert:
      - type: javascript
        value: "output.success === true"
      - type: llm-rubric
        value: "Shows opportunities sorted by close date, soonest first"
```

Three-turn chain:

```yaml
  - description: "User asks for opportunities"
    vars:
      utterance: "Show me opportunities closing this month"
      conversationId: chain
    assert:
      - type: llm-rubric
        value: "Lists opportunities closing this month"

  - description: "User narrows down"
    vars:
      utterance: "Which of those is the largest deal?"
      conversationId: chain
    assert:
      - type: llm-rubric
        value: "Identifies one opportunity as the largest"

  - description: "User acts on the result"
    vars:
      utterance: "Create a follow-up task for it"
      conversationId: chain
    assert:
      - type: llm-rubric
        value: "Confirms task creation for the opportunity discussed"
```

### Single-turn

Omit `conversationId` for standalone tests:

```yaml
tests:
  - vars:
      utterance: "how much Apex code is in this org?"
    assert:
      - type: javascript
        value: "output.success === true"
      - type: llm-rubric
        value: "Returns the count or list of Apex classes"
```

## Convention

Test files live in `agent-eval/` at the project root:

```
agent-eval/
  regression.yaml       # multi-turn regression tests
  regression-test.yaml  # single-turn, mirrors Testing Center
  .env                  # agent config + API keys (gitignored)
  package.json          # ESM support
  CLAUDE.md             # status notes
```

YAML files reference the provider via relative path:

```yaml
providers:
  - id: "file://../.claude/skills/agent-eval/providers/salesforce-agent.mjs"
    label: "MyAgentName"
```

## Commands

### `/agent-eval run` — Run evaluations

Run a specific suite:

```bash
cd agent-eval && npx promptfoo@latest eval -c regression.yaml --env-file .env
```

Run all suites:

```bash
cd agent-eval && for f in *.yaml; do npx promptfoo@latest eval -c "$f" --env-file .env; done
```

View results: `npx promptfoo@latest view`

### `/agent-eval port` — Convert Testing Center tests to Promptfoo

Read the Testing Center XML at `regressions/aiEvaluationDefinitions/*.aiEvaluationDefinition-meta.xml` and convert to Promptfoo YAML.

#### Testing Center XML structure (for reference)

Single-turn test:

```xml
<testCase>
    <number>1</number>
    <inputs>
        <utterance>which opportunity should I focus on next</utterance>
    </inputs>
    <expectation>
        <name>topic_assertion</name>
        <expectedValue>MyTopicName</expectedValue>
    </expectation>
    <expectation>
        <name>actions_assertion</name>
        <expectedValue>['QueryRecords']</expectedValue>
    </expectation>
    <expectation>
        <name>bot_response_rating</name>
        <expectedValue>Recommends an opportunity based on value and close date</expectedValue>
    </expectation>
</testCase>
```

Multi-turn test (fake history — Testing Center tells the agent "pretend this happened"):

```xml
<testCase>
    <number>10</number>
    <inputs>
        <utterance>Sort that by close date instead</utterance>
        <conversationHistory>
            <role>user</role>
            <message>Show me my opportunities</message>
            <index>0</index>
        </conversationHistory>
        <conversationHistory>
            <role>agent</role>
            <message>Here are your opportunities sorted by name...</message>
            <index>1</index>
        </conversationHistory>
    </inputs>
    <expectation>
        <name>bot_response_rating</name>
        <expectedValue>Confirms it will sort by close date</expectedValue>
    </expectation>
</testCase>
```

#### Conversion rules

- `<utterance>` → `vars.utterance`
- `<conversationHistory>` with `role=user` → earlier test cases with the same `conversationId`
- `<conversationHistory>` with `role=agent` → drop (agent responses are real in Promptfoo)
- `<expectation name="topic_assertion">` → skip (not visible through API)
- `<expectation name="actions_assertion">` → skip (not visible through API)
- `<expectation name="bot_response_rating">` → `llm-rubric` assertion

#### Converted multi-turn example

The Testing Center test above becomes two real conversation turns:

```yaml
  - description: "User asks for opportunities"
    vars:
      utterance: "Show me my opportunities"
      conversationId: sort-pref
    assert:
      - type: javascript
        value: "output.success === true"

  - description: "User asks to sort differently"
    vars:
      utterance: "Sort that by close date instead"
      conversationId: sort-pref
    assert:
      - type: javascript
        value: "output.success === true"
      - type: llm-rubric
        value: "Confirms it will sort by close date"
```

No fake agent response. Each turn is a real API call. The agent actually responds.

## Provider response format

```json
{
  "success": true,
  "text": "Agent response text",
  "sessionId": "uuid",
  "error": "error message if failed"
}
```

Use `output.success`, `output.text`, `output.sessionId` in assertions.

## Key differences from Testing Center

| Capability               | Testing Center          | Promptfoo                           |
|--------------------------|-------------------------|-------------------------------------|
| Multi-turn conversations | Fake (injected history) | Real (replayed API calls)           |
| Per-turn assertions      | Final turn only         | Every turn                          |
| Response quality judge   | SF built-in, opaque     | Your choice (o3-mini, Claude, etc.) |
| Topic/action assertions  | Yes                     | No (runtime internal)               |
| Test format              | XML, deploy to test     | YAML, run from CLI                  |
