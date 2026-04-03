# /agentforce port — Convert Testing Center to Promptfoo

Read Testing Center XML and convert to Promptfoo YAML for real multi-turn testing.

## Source

Testing Center definitions live at:
`regressions/aiEvaluationDefinitions/*.aiEvaluationDefinition-meta.xml`

## Conversion rules

- `<utterance>` → `vars.utterance`
- `<conversationHistory>` with `role=user` → earlier test cases with the same `conversationId`
- `<conversationHistory>` with `role=agent` → drop (agent responses are real in Promptfoo)
- `<expectation name="topic_assertion">` → skip (not visible through API)
- `<expectation name="actions_assertion">` → skip (not visible through API)
- `<expectation name="bot_response_rating">` → `llm-rubric` assertion

## Output

Write the converted YAML to `agentforce-eval/` alongside existing test files.
