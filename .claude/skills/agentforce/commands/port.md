# /agentforce port — Convert Testing Center XML to multi-turn entries

Read Testing Center XML and convert each `testCase` into an entry in `agent-eval/regression.test.yaml` (see `commands/eval.md` → "Multi-turn agent tests (REST)").

## Source

Testing Center definitions live at:
`agent-eval/*.aiEvaluationDefinition-meta.xml`

Each XML file may contain multiple `testCase` blocks (e.g. one combined `Regression.aiEvaluationDefinition-meta.xml` with one case per action).

## Conversion rules

- `<utterance>` → entry's `say` (single-turn) or last `turns[].say` (when there's prior history)
- `<conversationHistory>` with `role=user` → earlier `turns[]` in the same entry, in order, sharing the same session
- `<conversationHistory>` with `role=agent` → drop (real agent responses come from the live session)
- `<expectation name="topic_assertion">` → drop. The REST path can't observe planner trace; if routing matters, fold it into the `expect` string ("...recommends Acme as the top priority, sourced from open opportunities").
- `<expectation name="actions_assertion">` → drop, same reason. Fold action-routing intent into `expect` ("...creates a task on the Acme opportunity").
- `<expectation name="bot_response_rating">` → entry's `expect` (single-turn) or final `turns[].expect` (multi-turn)

## Output

Append a new entry to `agent-eval/regression.test.yaml`. Use the testCase's API name as `name`. Single-utterance cases should use the `say`/`expect` shorthand at the test root; cases with conversation history should use `turns:`.

Run with the standard agentforce-eval flow: drive each entry over the in-org `generateAiAgentResponse` Invocable Action REST endpoint, judge each turn against its `expect` in memory.
