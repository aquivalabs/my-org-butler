---
name: agent-eval
description: Evaluate Agentforce agents externally using Promptfoo — run evals, port Testing Center tests, red-team, compare results
argument-hint: [run|port|redteam|compare]
allowed-tools: Read, Grep, Glob, Bash, Write, Edit
---

# External Agent Evaluation

You are an expert at evaluating Salesforce Agentforce agents using external tools. Currently uses [Promptfoo](https://promptfoo.dev) as the evaluation engine.

## Architecture

```
Promptfoo CLI -> Generic JS Provider -> Salesforce Invocable Action API -> Agentforce
                 (providers/salesforce-agent.mjs)
                 POST /services/data/{API_VERSION}/actions/custom/generateAiAgentResponse/{AGENT_NAME}
```

No custom Apex endpoint needed. The provider authenticates via `sf org display` and calls the standard Invocable Action REST API.

The provider is **generic** — agent name and API version come from environment variables (`AGENT_NAME`, `API_VERSION`), not hardcoded values. This makes it reusable across any Agentforce agent.

## Convention

Test configuration lives in `agent-eval/` at the project root:

- `agent-eval/*.yaml` — test suite files (e.g. `regression-test.yaml`, `smoke.yaml`)
- `agent-eval/.env` — `AGENT_NAME`, `API_VERSION`, `OPENAI_API_KEY`
- `agent-eval/package.json` — ESM support (`"type": "module"`)

The skill's generic provider lives in `.claude/skills/agent-eval/providers/salesforce-agent.mjs`. Test YAML files reference it via relative path:
```yaml
providers:
  - id: "file://../.claude/skills/agent-eval/providers/salesforce-agent.mjs"
```

## Commands

### `/agent-eval run` — Run the evaluation suite

Discover all `.yaml` files in `agent-eval/` and run them:
```bash
cd agent-eval && for f in *.yaml; do npx promptfoo@latest eval -c "$f" --env-file .env; done
```
Or run a specific suite: `npx promptfoo@latest eval -c regression-test.yaml --env-file .env`

Then view results: `npx promptfoo@latest view`

### `/agent-eval port` — Port Testing Center tests to Promptfoo

Read the Testing Center XML at `regressions/aiEvaluationDefinitions/*.aiEvaluationDefinition-meta.xml` and convert each `<testCase>` to a Promptfoo YAML test entry in `agent-eval/`.

**Mapping rules:**
- `<utterance>` -> `vars.utterance`
- `<conversationHistory>` -> `vars.conversationHistory` as JSON array string: `'[{"role":"user","message":"..."},{"role":"agent","message":"..."}]'`
- `<expectation name="topic_assertion">` -> Skip (not visible through API)
- `<expectation name="actions_assertion">` -> Skip (not visible through API)
- `<expectation name="bot_response_rating">` -> `llm-rubric` assertion

**Template for each test:**
```yaml
  # {number}: {description}
  - vars:
      utterance: "{utterance text}"
    assert:
      - type: javascript
        value: "output.success === true"
      - type: llm-rubric
        value: "{bot_response_rating expectedValue}"
```

**Multi-turn template** (when `<conversationHistory>` exists):
```yaml
  - vars:
      utterance: "{utterance text}"
      conversationHistory: '[{"role":"{role}","message":"{message}"},...]'
    assert:
      - type: javascript
        value: "output.success === true"
      - type: llm-rubric
        value: "{bot_response_rating expectedValue}"
```

### `/agent-eval redteam` — Red-team the agent

Create a `redteam.yaml` in `agent-eval/` with adversarial test config:

```yaml
redteam:
  purpose: "Salesforce AI assistant that queries data, creates records, calls APIs, and manages user preferences"
  numTests: 5
  injectVar: utterance
  plugins:
    - harmful:privacy
    - harmful:misinformation
    - excessive-agency
    - hijacking
    - overreliance
    - politics
    - contracts
  strategies:
    - jailbreak
    - prompt-injection
    - crescendo
  provider: "file://../.claude/skills/agent-eval/providers/salesforce-agent.mjs"
```

Run with: `cd agent-eval && npx promptfoo@latest redteam run --env-file .env`
View report: `npx promptfoo@latest redteam report`

### `/agent-eval compare` — Compare with Testing Center

Run both tools and compare:
```bash
# Testing Center
time sf agent test run --api-name Regression_Test --wait 15

# Promptfoo
cd agent-eval && time npx promptfoo@latest eval -c regression-test.yaml --no-cache --env-file .env
```

See `agent-eval/COMPARISON.md` for benchmark results and rationale.

## Key Differences from Testing Center

| Capability | Testing Center | Promptfoo |
|---|---|---|
| Topic routing assertions | Yes | No (runtime internal) |
| Action invocation assertions | Yes | No (runtime internal) |
| Response quality (LLM judge) | SF built-in judge | Your choice (o3-mini, Claude, etc.) |
| Red teaming / adversarial | None | 50+ vulnerability types |
| Auto-generated tests | None | Yes (red team plugins) |
| Test format | Verbose XML | Clean YAML |
| CI/CD integration | `sf agent test run` parsing | Native JSON/CSV output |
| Multi-turn | Injects fake history | Replays real conversations |
| Results UI | SF Testing Center | `promptfoo view` web dashboard |

## Provider Response Format

The provider returns:
```json
{
  "success": true|false,
  "text": "Agent response text (parsed from JSON wrapper)",
  "sessionId": "uuid",
  "error": "error message if failed"
}
```

Use `output.success`, `output.text`, `output.sessionId` in assertions.
