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

## Experiment results

(Appended automatically after each experiment)
