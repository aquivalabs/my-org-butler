# Deploying

Never run `sf project deploy start --source-dir force-app`. The scratch org is namespaceless but some metadata files contain namespace references, so a full deploy always fails. Always deploy only the specific files you changed:

```
sf project deploy start \
  --source-dir force-app/main/default/classes/Foo.cls \
  --source-dir force-app/main/default/classes/Bar.cls
```

# Testing Strategy

Everything lives in `agent-eval/`. Three test layers, zero overlap:

## Testing Center (single-turn, per-action)

One XML per action in `agent-eval/<ActionName>.aiEvaluationDefinition-meta.xml`. Single `testCase` each. Runs on-platform via `sf agent test run --api-name <ActionName>`.

Run all in parallel (~2 min total vs 5–10 min serial):

```bash
mkdir -p /tmp/ae && rm -f /tmp/ae/*.json
for f in agent-eval/*.aiEvaluationDefinition-meta.xml; do
  name=$(basename "$f" .aiEvaluationDefinition-meta.xml)
  (sf agent test run --api-name "$name" --wait 10 --result-format json > "/tmp/ae/$name.json" 2>&1) &
done
wait
```

Parsing + retry logic is in `.claude/skills/agentforce/commands/eval.md`.

## Promptfoo Demo Story (multi-turn)

`agent-eval/demo-story.yaml` — the conference demo automated. Multi-turn conversation chaining actions into a sales-rep workflow.

```
cd agent-eval && npx promptfoo@latest eval -c demo-story.yaml --env-file .env
```

## Promptfoo Prompt Tests (template isolation)

`agent-eval/prompt-regression.yaml` — smoke test for the prompt template provider via Generations REST API.

```
cd agent-eval && npx promptfoo@latest eval -c prompt-regression.yaml --env-file .env
```

## LLM Judge

Rubrics assert on **specific data** (filenames, dollar amounts, counts) — not vague "confirms it worked." Judge model: `gpt-4o-mini`.

## .env

Two values: `OPENAI_API_KEY` (LLM judge) and `CONTENT_DOCUMENT_ID` (sample file).

# Current State (2026-04-20)

Testing Center suite has **14 per-action tests** in `agent-eval/`. Parallel run completes in ~2 min. Typical result: **12 clean PASS, 0 real FAIL, 2 polling crashes** (CLI-side bug `TestPollFailed: no constant with the specified name: RETRY` — tests complete server-side, just need re-polling).

**Main open issue: [#56](https://github.com/aquivalabs/my-org-butler/issues/56)** — Data Cloud routing nondeterminism. Tests 8 (SearchDataLibrary) and the Data Cloud ones (QueryDataCloud) sometimes route correctly and sometimes skip the action. Real question: is the agent reasoning itself unstable, or are the tests wrong? Done criteria: four consecutive 100% runs.
