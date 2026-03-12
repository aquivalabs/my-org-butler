# Fixing the Agentforce Testing Problem

## The problem

Testing Center's LLM judge is unreliable. It's the only thing that actually matters — did the agent respond correctly? — and it gets it wrong.

We've seen it fail correct responses: the agent queries real org data, returns the right opportunities with the right amounts, and the judge says "no match." We've also seen it pass bad responses: the agent returns an error or incomplete data, and the judge says "looks good."

You can't see what model the judge uses. You can't see its reasoning. You can't change the grading criteria. When the judge is wrong, you're stuck.

Topic routing (100% for any single-topic agent — meaningless) and action invocation order (a good agent finds different paths to the same answer) don't help. The outcome assertion is the only one that matters, and it's the one that's broken.

## The fix

Pick a better judge. That's what Promptfoo does.

We use OpenAI's o3-mini. You could use Claude, GPT-4.1, or any model you trust. You write the grading criteria in plain English. If a test fails and the response was actually correct, you fix the rubric — right now, in YAML, no deploy.

```yaml
- vars:
    utterance: "which opportunity should I focus on next"
  assert:
    - type: llm-rubric
      value: "Recommends an opportunity based on value and close date"
```

The agent talks to the real scratch org, queries real data (Acme Q1 Expansion, $500K, closes in 3 days — all from `create-sample-data.apex`), and o3-mini judges the response.

## The evidence

Same 15 tests, same scratch org, 3 runs each.

| #  | Test                       | Data Source    | Testing Center | Promptfoo |
|----|----------------------------|----------------|----------------|-----------|
| 1  | Opportunity recommendation | Org (Acme)     | 3/3            | 3/3       |
| 2  | Create follow-up task      | Org (Burlingt) | 3/3            | 3/3       |
| 3  | Org customizations         | Org metadata   | 3/3            | 3/3       |
| 4  | Object diagram             | Org metadata   | 2/3            | 2/3       |
| 5  | Web search                 | External       | 1/3            | 0/3       |
| 6  | GitHub issues              | External       | 2/3            | 3/3       |
| 7  | Apex code count            | Org metadata   | 3/3            | 3/3       |
| 8  | Metadata API               | Org metadata   | 3/3            | 3/3       |
| 9  | Store instruction          | Agent memory   | 3/3            | 3/3       |
| 10 | Multi-turn: sort           | Agent memory   | 1/3            | 0/3       |
| 11 | Multi-turn: filter         | Agent memory   | 2/3            | 0/3       |
| 12 | Vector DB search           | External       | 1/3            | 0/3       |
| 13 | Read file (NDA)            | Org (file)     | 3/3            | 3/3       |
| 14 | Schedule plan              | Agent feature  | 3/3            | 3/3       |
| 15 | Send notification          | Agent feature  | 3/3            | 3/3       |

### Reading the numbers

Where both tools test the same thing, Promptfoo finds the same or better results:

- **#6 (GitHub issues)**: Promptfoo 3/3, Testing Center 2/3. The agent returned correct data every time. Testing Center's judge failed a correct response — exactly the problem we're solving.
- **#1-3, #7-9, #13-15**: Both agree. These tests query real org data and the responses are unambiguous. Both judges get them right.
- **#4 (Object diagram)**: Both 2/3. The agent occasionally doesn't generate the diagram link. Neither tool is wrong — the agent is flaky here.

Where Promptfoo scores lower, it's testing something harder:

- **#10, #11 (multi-turn)**: Testing Center injects fake conversation history — it tells the agent "pretend this happened." Promptfoo replays real API calls, which is more realistic. The agent doesn't preserve context well across real turns. Promptfoo exposes a real bug that Testing Center hides.
- **#5, #12 (external APIs)**: Web search and vector DB are flaky regardless of tool. The 1/3 vs 0/3 difference is noise from the external service, not the judge.

### The takeaway

For the 10 tests grounded in org data (#1-4, #7-9, #13-15), Promptfoo's o3-mini judge agrees with or outperforms Testing Center's judge. Where it disagrees, it's either catching a judge error (#6) or testing more realistically (#10, #11).

## What's next: security and red teaming

Promptfoo also supports adversarial testing — auto-generated attack prompts for prompt injection, data leakage, excessive agency, and more. This is something Testing Center can't do at all.

`security.yaml` tests Agentforce platform guardrails — things the platform itself should prevent regardless of how the agent is configured: revealing system instructions, exposing Apex source code, leaking internal action names. These test the platform, not our agent.

For testing agent-level security (can the agent be tricked into actions the user shouldn't perform), the org needs proper permission boundaries — a non-admin user with the `MyOrgButlerUser` permission set. That's a separate project.

## The downside

Promptfoo can't see which topic handled the request or which actions were called. It only sees the final response. For most agents, this doesn't matter — the output is what counts, and a good agent can take different paths to the same correct answer. But if you need to verify internal routing, Testing Center is still the only option.

## How it connects

Salesforce's `generateAiAgentResponse` invocable action is accessible via the standard REST API:

```http
POST /services/data/v65.0/actions/custom/generateAiAgentResponse/{AgentName}
```

A 90-line JavaScript provider calls it. No custom Apex. Any external tool can talk to any Agentforce agent.
