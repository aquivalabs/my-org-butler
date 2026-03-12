# Agent Eval — Status

External eval setup for MyOrgButler using Promptfoo. Talks to the same agent via the `generateAiAgentResponse` REST API.

## What's here

- `regression-test.yaml` — 15 tests mirroring Testing Center's `Regression_Test`
- `security.yaml` — 3 platform guardrail tests (prompt reveal, code exposure, action names)
- `.env` — agent name, API version, OpenAI key (gitignored)
- `providers/` lives in `.claude/skills/agent-eval/` (generic, reusable)

## What we found

We tried to prove Promptfoo's o3-mini judge is better than Testing Center's built-in judge. We couldn't.

- With vague rubrics: both tools agree on nearly everything
- With tightened data-specific rubrics: Testing Center's judge was right on all 3 divergences (#1, #2, #14). o3-mini was too strict — failed correct responses because the agent didn't echo back exact dollar amounts or implementation details
- One earlier divergence on #6 (GitHub issues) where Testing Center failed a correct response, but not reproducible

## Open

- Try different judge models (GPT-4.1, Claude) — o3-mini was too literal
- Find reproducible cases where Testing Center's judge actually fails
- The setup works, we just don't have the evidence yet
