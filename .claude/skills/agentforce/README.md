# /agentforce

Test and deploy Agentforce agents.

## What this skill solves

1. **Testing Center fakes conversations.** Its `conversationHistory` lets you script both sides — the agent never actually responds. No real session state. A mockup, not a test. The skill drives a real session over the in-org `generateAiAgentResponse` invocable action endpoint via `sf api request rest`, so each turn gets a real reply.
2. **Prompt templates need regression testing.** They run inside Flows, Apex, and agent actions; LLM output can regress just as easily as agent conversations. `agent-eval/prompt-regression.yaml` exercises specific prompt templates (`ConsolidateMemory`, `AnswerFromFile`) through the agent so changes that break their behavior fail loudly.
3. **Salesforce CLI has metadata-iteration gaps.** Schema-only edits don't get detected, prompt-template version identifiers must be bumped manually, planner bundles cache aggressively, active agents block deploys. The skill encodes the workarounds.

## Commands

- [`/agentforce eval`](commands/eval.md) — run regression tests against the agent (Testing Center single-turn + REST multi-turn)
- [`/agentforce port`](commands/port.md) — convert multi-turn Testing Center XML cases into entries in `agent-eval/demo-story.yaml`
- [`/agentforce deploy`](commands/deploy.md) — apply the metadata-iteration fixups Salesforce CLI doesn't handle

## Real agent conversations

Multi-turn with real session state. The agent actually responds at each turn — no scripted history. `run.mjs` handles the REST calls, `sessionId` chaining, and response unwrapping; Claude judges each turn's reply against its plain-English `expect`.

```yaml
agent: MyOrgButler

tests:
  - name: SalesRepMondayMorning
    description: "MyOrgButler Demo — A Sales Rep's Monday Morning"
    turns:
      - turn: 'Prioritize: what needs my attention?'
        say: which opportunity should I work on next?
        expect: Recommends the Acme Q1 Expansion Deal as the top priority opportunity to work on
      - turn: 'Act: create the follow-up'
        say: create a task to call Acme about the discount
        expect: Confirms a task was created on the Acme opportunity
```

Turns within the same `tests[]` entry share one agent session — context carries automatically via the returned `sessionId`.
