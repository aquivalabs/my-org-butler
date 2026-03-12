# Agent Eval

External evaluation for Agentforce agents using [Promptfoo](https://promptfoo.dev).

## The problem with Testing Center

Testing Center's biggest problem is its LLM judge. It's unreliable. We've seen it grade correct responses as failures — the agent returns exactly the right data, and the judge says "no match." We've also seen it pass responses that were clearly wrong. You can't see what model it uses, you can't see its reasoning, and you can't fix the grading criteria when it's wrong.

On top of that, Testing Center checks topic routing and action invocation order. For a single-topic agent, topic routing is trivially 100% — it means nothing. Action order is also misleading: a good agent can take different paths to the same correct answer. Testing Center would fail that test even though the response is perfect.

## What this solves

Promptfoo lets you pick the LLM judge. We use OpenAI's o3-mini, but you could use Claude, GPT-4.1, or anything else. You write the grading criteria yourself. If a test is wrong, you fix the rubric — not file a case with Salesforce.

The test is just YAML:

```yaml
- vars:
    utterance: "which opportunity should I focus on next"
  assert:
    - type: llm-rubric
      value: "Recommends an opportunity based on value and close date"
```

The agent talks to the real org, queries real data, and the judge you chose evaluates the response.

## The downside

Promptfoo only sees the final text response. It can't see which topic handled the request or which actions were called. For most agents, this doesn't matter — the output is what counts. But if you need to verify internal routing, Testing Center is the only option.

## How it works

Salesforce's `generateAiAgentResponse` invocable action is accessible via the standard REST API:

```http
POST /services/data/v65.0/actions/custom/generateAiAgentResponse/{AgentName}
```

A small JavaScript provider calls this API, gets the response, and feeds it to Promptfoo for judging. No custom Apex needed.

## Setup

Configure `agent-eval/.env`:

```env
AGENT_NAME=MyOrgButler
API_VERSION=v65.0
OPENAI_API_KEY=sk-...
```

Make sure `sf org display` returns a valid auth token.

## Usage

```bash
cd agent-eval

# Regression tests (mirrors Testing Center's Regression_Test)
npx promptfoo@latest eval -c regression-test.yaml --env-file .env

# Platform guardrail tests (prompt leaks, code exposure)
npx promptfoo@latest eval -c security.yaml --env-file .env

# View results
npx promptfoo@latest view
```

## Files

- `regression-test.yaml` — 15 test cases ported from Testing Center, against real org data
- `security.yaml` — tests Agentforce platform guardrails (prompt reveal, code exposure)
- `.env` — agent name, API version, judge API key
- `COMPARISON.md` — benchmark results and analysis
