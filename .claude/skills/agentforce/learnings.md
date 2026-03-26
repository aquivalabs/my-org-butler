# Prompt Optimization Learnings

Accumulated knowledge from experiments. Read this before proposing any experiment. Append after every experiment.

## General principles (seed)

### Prompt simplification
- Shorter prompts often perform as well as verbose ones on simple tasks (merge, classify, extract)
- Good/bad examples in prompts are expensive in tokens but rarely improve output on capable models — test removing them first
- ALL CAPS instructions ("NEVER", "ALWAYS") add no value over normal casing — LLMs don't respond to shouting
- XML tags (`<rules>`, `<input>`) can improve structure without adding tokens — especially for weaker models

### Model selection
- For simple text tasks (merge, reformat, classify), cheaper models often match expensive ones in quality but at 2-5x lower latency
- Flash/Mini models excel at structured output and instruction following — they struggle more with nuance and creativity
- Always include the current model as baseline — sometimes the original is already optimal
- Model performance varies by task complexity: test, don't assume

### Prompt rewriting
- Rewriting a prompt with the model that will run it can improve alignment — the model "understands its own style"
- Removing meta-instructions ("Return ONLY the result, no commentary") is worth testing — most models already do this by default
- Consolidating overlapping rules reduces confusion — 3 clear rules beat 5 overlapping ones

### What to measure
- `latencyMs` is the primary optimization target for most prompt templates — users feel latency
- Quality is a gate, not a target — a variant must pass all assertions, then lowest latency wins
- Safety scores rarely vary between variants of the same prompt — don't optimize for them unless there's a specific concern

## Process learnings

### Deployment
- New prompt templates deploy without an active version. Must do a deploy-retrieve-redeploy cycle: deploy first to create the version, retrieve to get the server-generated `versionIdentifier` hash, add `activeVersionIdentifier` matching that hash, then redeploy.
- Not all models are available in all scratch org regions. If a variant silently fails to deploy, check model availability. Retrieve to confirm the template exists before running tests.

### Running experiments
- First API call to a template is always slow (cold start / caching). Always use `--repeat 3` minimum to get reliable latency numbers.
- Salesforce adds ~1s overhead per call (trust layer, template resolution). This is the latency floor — no model can go below it.
- The Generations REST API requires `Input:` prefix on valueMap keys and `additionalConfig` with `applicationName: "PromptTemplateGenerationsInvocable"`. Without these it returns INTERNAL_ERROR.
