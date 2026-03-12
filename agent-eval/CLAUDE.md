# Agent Eval

External evaluation for MyOrgButler using Promptfoo. Real multi-turn conversations via the Salesforce `generateAiAgentResponse` REST API.

## LinkedIn article planned

Write a blog article about this. Key narrative:

### The journey (honest)

1. Started trying to prove Promptfoo's LLM judge (o3-mini) is better than Testing Center's built-in judge
2. Ran 15 identical tests on both tools, vague rubrics and tight data-specific rubrics
3. Result: couldn't prove it. Both judges are roughly equivalent. On tightened rubrics, Testing Center's judge was actually MORE correct — o3-mini was too strict, failing correct responses
4. Pivoted to multi-turn — and found the real differentiator

### The finding (the story)

Testing Center fakes multi-turn conversations. It injects hardcoded XML history — you literally write what the agent said. The agent never said it. No real session state.

Promptfoo calls the real agent at every turn. Session state builds up via `sessionId`. Each turn gets its own assertion.

### The proof (show this)

Conversation 4 (correction) — 3 turns, all real:
- Turn 1: "How many opportunities does Acme have?" → "3 opportunities" (real query)
- Turn 2: "I meant only Acme Corporation" → "Got it, I'll narrow to Acme Corporation" (real session)
- Turn 3: "Show me their largest deal" → "Acme Cloud Migration Project, $800K" (real context maintained)

All sharing `sessionId: 08b69619`. Testing Center can't do this.

### The bug we found

The agent loses context for pronoun resolution. "Which of those is the largest?" → "Could you clarify which deals?" The agent forgot what it just listed. Testing Center hides this by injecting fake history.

### The format (show the YAML)

```yaml
- description: "User asks about Acme"
  vars:
    utterance: "How many opportunities does Acme have?"
    conversationId: correction
  assert:
    - type: llm-rubric
      value: "Returns a count of Acme opportunities"

- description: "User corrects the scope"
  vars:
    utterance: "I meant only Acme Corporation"
    conversationId: correction
  assert:
    - type: llm-rubric
      value: "Acknowledges the correction"
```

`conversationId` links turns. Provider caches `sessionId`. That's the entire mechanism.

### The skill

There's a Claude Code skill at `.claude/skills/agent-eval/` that can write these tests and convert Testing Center XML. Point readers to the repo.

## Files

- `regression.yaml` — 5 multi-turn conversations (13 turns), per-turn assertions
- `regression-test.yaml` — 15 single-turn tests mirroring Testing Center's `Regression_Test`
- `.env` — `AGENT_NAME`, `API_VERSION`, `OPENAI_API_KEY` (gitignored)

## Technical details

- Provider: `.claude/skills/agent-eval/providers/salesforce-agent.mjs` (90 lines)
- Session cache: `Map<conversationId, sessionId>` — reuses sessionId across turns
- `maxConcurrency: 1` required so turns run in order
- API: `POST /services/data/{version}/actions/custom/generateAiAgentResponse/{agent}`
- Auth: `sf org display --json` (cached)

## What didn't work

- `turns` YAML array format: Promptfoo expands arrays in vars into separate test cases
- Proving judge quality difference: both judges are roughly equivalent for single-turn
- Red teaming: requires email verification, abandoned
- Security tests: platform guardrails work but aren't differentiating (Testing Center can test the same things)

## Results (last run)

- Multi-turn (`regression.yaml`): 11/13 passed (85%). 2 failures are real agent context-loss bugs.
- Single-turn (`regression-test.yaml`): 10/15 passed (67%). Failures are flaky external services.

## Open

- Admin vs standard user personas for different test suites
- Investigate agent's pronoun resolution context-loss bug
- Branch: `feature/multi-turn-testing-promptfoo`
