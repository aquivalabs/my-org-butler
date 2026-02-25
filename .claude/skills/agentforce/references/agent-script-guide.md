# Agent Script — Condensed Guide

> **Purpose:** This is a condensed working reference for AI-assisted Agent Script development.
> It captures the mental model, gotchas, and practical patterns that make an AI assistant effective —
> not a duplicate of the official docs. For full syntax details, block definitions, and deep dives,
> **always fetch the official documentation** from `references/official-sources.md`.

---

## What It Is

Agent Script is a YAML-like DSL for Agentforce agents. It compiles into an "Agent Graph" consumed by the Atlas Reasoning Engine. The core idea: you mix **deterministic logic** (`->` arrow blocks) with **LLM prompts** (`|` pipe blocks). Logic always runs. Prompts are suggestions the LLM interprets.

Official docs: [Overview](https://developer.salesforce.com/docs/ai/agentforce/guide/agent-script.html) | [Language](https://developer.salesforce.com/docs/ai/agentforce/guide/ascript-lang.html)

---

## The Two Modes: `->` vs `|`

This is the single most important concept. Everything else is plumbing around this duality.

| After `->` | After `|` |
|------------|----------|
| Deterministic — always executes | LLM prompt text — LLM interprets |
| `run`, `set`, `if/else`, `transition to` | Natural language + `{!interpolation}` |

**Execution model:** All `->` logic resolves first, then the collected `|` text is sent to the LLM as a single prompt. The LLM cannot influence earlier deterministic branching.

Official docs: [Instructions](https://developer.salesforce.com/docs/ai/agentforce/guide/ascript-ref-instructions.html) | [Flow of Control](https://developer.salesforce.com/docs/ai/agentforce/guide/ascript-flow.html)

---

## File Structure

Block order matters. Indentation: **at least 2 spaces or 1 tab** — pick one, don't mix.

```
config:           # Identity — required
system:           # Global messages & instructions
language:         # Locale settings (optional)
connection:       # Channel config like Enhanced Chat (optional)
variables:        # Global state — shared across all topics
start_agent:      # Entry point — routes to first topic
topic <name>:     # One or more topics — where the work happens
```

Official docs: [Blocks](https://developer.salesforce.com/docs/ai/agentforce/guide/ascript-blocks.html)

---

## Three Ways to Run Actions

1. **`run @actions.x` in `->` block** — 100% deterministic, always executes
2. **`{!@actions.x}` in `|` block** — suggestion, LLM decides
3. **`reasoning.actions` block** — LLM picks from toolbox

Official docs: [Actions](https://developer.salesforce.com/docs/ai/agentforce/guide/ascript-ref-actions.html) | [Tools](https://developer.salesforce.com/docs/ai/agentforce/guide/ascript-ref-tools.html)

---

## Input Binding — Three Flavors

```agentscript
with order_id = @variables.order_id    # Bound — explicit value
with order_id = "FIXED_VALUE"          # Fixed — hardcoded
with order_id = ...                    # Slot-fill — LLM asks user & fills it
```

Slot-filling (`...`) works for top-level action inputs only, **not for chained action inputs**.

---

## Topic Navigation

| Mechanism | Syntax | Returns? |
|-----------|--------|----------|
| **Transition** | `transition to @topic.x` or `@utils.transition to @topic.x` | No — one-way |
| **Delegation** | `@topic.x` as reasoning action | Yes — like a function call |

Official docs: [Utils](https://developer.salesforce.com/docs/ai/agentforce/guide/ascript-ref-utils.html) | [Transitions pattern](https://developer.salesforce.com/docs/ai/agentforce/guide/ascript-patterns-transitions.html)

---

## Key Gotchas the Docs Won't Emphasize

These are hard-won from real usage. The official docs describe these features, but don't highlight how easy it is to get them wrong:

1. **No `else if`** — Must use nested `if`/`else` blocks. This is the #1 syntax mistake.
2. **`mutable` is required** for any variable the agent needs to change. Forgetting it is silent — the `set` just doesn't work.
3. **Boolean literals are case-sensitive** — `True`/`False` (capitalized). `true`/`false` won't work.
4. **`run` cannot go inside `|` blocks** — Logic must follow `->`. Putting `run` after `|` is a syntax error that's easy to miss.
5. **`...` (slot-fill) doesn't chain** — Only works for top-level reasoning action inputs, not inside deterministic `run` chains.
6. **Missing `description` on reasoning actions** — The LLM needs this to choose tools. No description = LLM ignores the tool.
7. **Actions are topic-scoped** — You can't reference `@actions.x` from a different topic.
8. **`after_reasoning` cannot contain `|` blocks** — Purely deterministic. Use `transition to` (not `@utils.transition to`) inside hooks.
9. **`start_agent` runs on every utterance** — Not just the first one. Guard your routing logic or you'll re-route on every message.
10. **`filter_from_agent: True`** on outputs hides them from LLM context but keeps them available for deterministic logic. Use for sensitive data the agent should act on but never surface.
11. **`@utils.setVariables`** uses `...` (ellipsis) token to instruct the LLM to slot-fill. Different from `set` which is deterministic.
12. **Arithmetic operators:** `+`, `-`, `*` are supported. Division is not documented.
13. **`num_turns` is NOT a built-in variable** — `@system_variables.user_input` is the only system variable. If you need turn counting, create a `mutable number` variable and increment it manually in `after_reasoning`.

Official docs: [Expressions](https://developer.salesforce.com/docs/ai/agentforce/guide/ascript-ref-expressions.html) | [Operators](https://developer.salesforce.com/docs/ai/agentforce/guide/ascript-ref-operators.html) | [Variables](https://developer.salesforce.com/docs/ai/agentforce/guide/ascript-ref-variables.html)

---

## Patterns Quick Index

The official docs now have excellent dedicated pattern pages. Fetch the specific one you need:

| When you need to... | Fetch |
|---------------------|-------|
| Chain actions in sequence | [Action Chaining](https://developer.salesforce.com/docs/ai/agentforce/guide/ascript-patterns-action-chaining.html) |
| Use `if/else` for branching | [Conditionals](https://developer.salesforce.com/docs/ai/agentforce/guide/ascript-patterns-conditionals.html) |
| Load data before prompting | [Fetch Data](https://developer.salesforce.com/docs/ai/agentforce/guide/ascript-patterns-fetch-data.html) |
| Show/hide tools with `available when` | [Filtering](https://developer.salesforce.com/docs/ai/agentforce/guide/ascript-patterns-filtering.html) |
| Force users through mandatory steps | [Required Flow](https://developer.salesforce.com/docs/ai/agentforce/guide/ascript-patterns-required-flow.html) |
| Reference resources in prompts | [Resource References](https://developer.salesforce.com/docs/ai/agentforce/guide/ascript-patterns-resource-references.html) |
| Override persona per topic | [System Overrides](https://developer.salesforce.com/docs/ai/agentforce/guide/ascript-patterns-system-overrides.html) |
| Design the entry point | [Topic Selector](https://developer.salesforce.com/docs/ai/agentforce/guide/ascript-patterns-topic-selector.html) |
| Navigate between topics | [Transitions](https://developer.salesforce.com/docs/ai/agentforce/guide/ascript-patterns-transitions.html) |
| Manage state across turns | [Variables](https://developer.salesforce.com/docs/ai/agentforce/guide/ascript-patterns-variables.html) |

---

## Syntax Cheat Sheet

| Symbol | Meaning |
|--------|---------|
| `->` | Procedure block (deterministic logic) |
| `\|` | Template/prompt string (for LLM) |
| `@variables.x` | Reference a variable in logic |
| `{!@variables.x}` | Interpolate a variable in `\|` blocks |
| `@actions.x` | Reference an action |
| `@topic.x` | Delegate to topic (returns) |
| `@utils.transition to` | One-way topic switch (no return) |
| `@utils.setVariables` | LLM slot-fills a variable |
| `@utils.escalate` | Hand off to human agent |
| `@outputs.x` | Action output (after `run` / in `set`) |
| `run` | Execute action deterministically |
| `set` | Store value in variable |
| `with` | Bind input parameter |
| `...` | LLM slot-fill (asks user, fills value) |
| `if / else` | Conditional branching (no `else if`) |
| `is None / is not None` | Null checks |
| `True / False` | Boolean literals (case-sensitive) |
| `@system_variables.user_input` | Only system variable — customer's latest utterance |
| `available when` | Guard clause for tools |
| `filter_from_agent` | Hide output from LLM context |
| `#` | Comment |

---

## Naming Rules

- Letters, numbers, underscores only
- Must start with a letter, cannot end with underscore
- No consecutive underscores (`__`), max 80 characters
- Convention: `snake_case`

---

## Migrating from Old Agentforce Builder

| Builder UI concept | Agent Script equivalent |
|-------------------|----------------------|
| Topic name | `topic my_topic_name:` |
| Classification description | `description:` on the topic |
| Scope / "what this topic can do" | `reasoning.instructions` + available `actions` |
| Instructions (text boxes) | `reasoning: instructions:|` (prompt) or `instructions:->` (logic) |
| Custom action (Flow/Apex/Prompt) | `actions:` block with `target: flow://` / `apex://` / `prompt://` |
| "Collect from user" | `with param = ...` (slot-fill) |
| "Use variable" / "Use constant" | `with param = @variables.x` / `with param = "value"` |
| "Show in conversation" / "Hide" | `filter_from_agent: True` on output |
| Require confirmation checkbox | `require_user_confirmation: True` |
| Guard conditions | `available when` on reasoning actions |

**New in Agent Script (no Builder equivalent):** `before_reasoning`/`after_reasoning` hooks, `linked` variables, per-topic `system.instructions`, delegation (`@topic.x` returns), conditional topic transitions, template arithmetic `{!expr}`, `language` block, `connection` block.

Official docs: [Examples](https://developer.salesforce.com/docs/ai/agentforce/guide/ascript-example.html) | [Recipes](https://developer.salesforce.com/sample-apps/agent-script-recipes/getting-started/overview)
