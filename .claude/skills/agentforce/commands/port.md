# /agentforce port — Convert Testing Center XML to multi-turn entries

Read Testing Center XML and convert each multi-turn `testCase` (one with `<conversationHistory>` blocks) into an entry in `agent-eval/demo-story.yaml` (see `commands/eval.md` → "Multi-turn agent tests (REST)").

**Skip single-utterance cases** — those stay in the Testing Center XML, where they get topic and action assertions the REST path can't reproduce. Only port cases that exercise multi-turn context.

## Source

Testing Center definitions live at:
`agent-eval/*.aiEvaluationDefinition-meta.xml`

Each XML file may contain multiple `testCase` blocks (e.g. one combined `Regression.aiEvaluationDefinition-meta.xml` with one case per action).

## Conversion rules

- `<utterance>` → final `turns[].say` of the entry
- `<conversationHistory>` with `role=user` → earlier `turns[]` in the same entry, in order, sharing the same session
- `<conversationHistory>` with `role=agent` → drop (real agent responses come from the live session)
- `<expectation name="topic_assertion">` → drop. The REST path can't observe planner trace; if routing matters, fold it into the `expect` string ("...recommends Acme as the top priority, sourced from open opportunities").
- `<expectation name="actions_assertion">` → drop, same reason. Fold action-routing intent into `expect` ("...creates a task on the Acme opportunity").
- `<expectation name="bot_response_rating">` → final `turns[].expect`

## Output

Append a new entry to `agent-eval/demo-story.yaml`. Use the testCase's API name as `name`. Each turn gets a short `turn` label summarizing what that turn probes. The entry-level `description` summarizes the scenario.

Run with the standard `/agentforce eval` flow: drive each entry over the in-org `generateAiAgentResponse` Invocable Action REST endpoint, judge each turn against its `expect` in memory.
