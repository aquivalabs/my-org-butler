---
name: agentforce
description: Write and edit Salesforce Agentforce Agent Script (.agent files). Use when creating agents, editing agent topics, writing reasoning instructions, defining actions, configuring variables, or troubleshooting Agent Script syntax. Covers the full Agent Script DSL including config, system, variables, start_agent, topic blocks, actions, tools, transitions, conditionals, lifecycle hooks, and template expressions.
---

# Agent Script

Write and troubleshoot Salesforce Agentforce agents using Agent Script — a YAML-like DSL for hybrid reasoning.

## How This Skill Works

This skill combines a **condensed local guide** with **live official documentation**.

- **`references/agent-script-guide.md`** — A slim reference covering the mental model, syntax cheat sheet, common gotchas, and migration guide. Read this first for quick answers.
- **`references/official-sources.md`** — The complete URL index for Salesforce's official Agent Script documentation (~28 pages). **Fetch these pages whenever you need full syntax details, block definitions, or pattern examples.**
- **`references/known-issues.md`** — Tracked bugs, deployment quirks, and workarounds discovered in this project. Check here first when something fails unexpectedly.

**Default behavior:** When writing or modifying Agent Script, always consult the local guide first. If the guide doesn't cover what you need, or if something fails, **fetch the relevant official doc page** before guessing. The official docs are the source of truth.

## Core Mental Model

Agent Script has exactly **two execution modes** inside `instructions:`:

| After `->` | After `|` |
|------------|----------|
| Deterministic logic — always executes | LLM prompt text — LLM interprets |
| `run`, `set`, `if/else`, `transition to` | Natural language + `{!interpolation}` |

Everything in the language is plumbing around this duality.

## Quick Syntax Reference

| Symbol | Meaning |
|--------|---------|
| `->` | Procedure block (deterministic logic) |
| `|` | Template/prompt string (for LLM) |
| `@variables.x` | Reference variable in logic |
| `{!@variables.x}` | Interpolate variable in `|` blocks |
| `@actions.x` | Reference an action |
| `@topic.x` | Delegate to topic (returns) |
| `@utils.transition to` | One-way topic switch (no return) |
| `@utils.setVariables` | LLM slot-fills a variable |
| `@utils.escalate` | Hand off to human |
| `@outputs.x` | Action output (after `run` / in `set`) |
| `run` | Execute action deterministically |
| `set` | Store value in variable |
| `with` | Bind input parameter |
| `...` | LLM slot-fill (asks user, fills value) |
| `if / else` | Conditional branching (no `else if` — nest instead) |
| `available when` | Guard clause for tools |
| `filter_from_agent` | Hide action output from LLM context |
| `#` | Comment |

## Three Ways to Run Actions

1. **`run @actions.x` in `->` block** — 100% deterministic, always executes
2. **`{!@actions.x}` in `|` block** — suggestion, LLM decides
3. **`reasoning.actions` block** — LLM picks from toolbox

## Topic Navigation

- `transition to @topic.x` / `@utils.transition to` → **one-way**, no return
- `@topic.x` as reasoning action → **delegation**, returns to caller after completion

## File Conventions

- Indentation: at least 2 spaces or 1 tab — pick one, don't mix
- Names: `snake_case`, letters/numbers/underscores, start with letter, max 80 chars
- Block order: `config → system → language → connection → variables → start_agent → topic(s)`

## When to Fetch Official Docs

**Always fetch** the relevant official doc page (via `references/official-sources.md`) in these situations:

- **Writing a block type for the first time in a session** — Fetch its reference page to confirm current syntax
- **Compilation/deployment error** → Fetch Blocks reference + specific element reference
- **Action not executing** → Fetch Actions reference AND Tools reference
- **Variable not updating** → Fetch Variables reference (mutable vs immutable, linked vs regular)
- **Topic transition wrong** → Fetch Utils + Transitions pattern page
- **Conditional not evaluating** → Fetch Expressions + Operators reference
- **Implementing a pattern** → Fetch the specific pattern page (action chaining, filtering, fetch data, etc.)
- **User contradicts the local guide** → Trust official docs; update local guide if needed
- **New/unfamiliar syntax** → Fetch the Language Characteristics page first

If a doc URL 404s, web-search `site:developer.salesforce.com agent script <topic>` as fallback.

## Self-Improvement

This skill's reference files are editable. When you discover something during a session that improves your understanding, **update the references directly**:

- **Found an error in the guide?** Fix it in place.
- **Official doc URL changed or 404'd?** Update `references/official-sources.md`.
- **Discovered a new gotcha or undocumented behavior?** Add it to the guide's gotchas section.
- **A recipe or example solved something tricky?** Add a note to the guide.

## Common Mistakes to Catch

- Forgetting `mutable` on variables the agent needs to change
- Using `else if` (doesn't exist — must nest `if`/`else`)
- Using `transition to` when they want delegation (one-way vs returns)
- Putting `run` statements inside `|` blocks (logic must follow `->`)
- Using `...` (slot-fill) in chained action inputs (only works for top-level)
- Missing `description` on reasoning actions (LLM needs this to choose tools)
- Referencing actions across topics (actions are topic-scoped)
- Using `true`/`false` instead of `True`/`False` (case-sensitive)
- Putting `|` blocks inside `after_reasoning` (hooks are purely deterministic)

## Repository Notes: My Org Butler

Use these notes when working in this repository.

### Coding and Structure

- Primary Agent Script bundle: `force-app/main/default/aiAuthoringBundles/MyOrgButler/`
- Apex actions: `force-app/main/default/classes/`
- Prompt templates: `force-app/main/default/genAiPromptTemplates/`
- Permissions: `force-app/main/default/permissionsets/`
- Optional regression tests: `regressions/aiEvaluationDefinitions/`

### Deployment and Publishing

- Validate and publish use different backend checks. A successful validate does not guarantee publish success.
- In namespaced scratch orgs for this project, `apex://` action targets must use namespace at publish-time (for example `apex://aquiva_os__LoadCustomInstructions`).
- Deploy from repository paths only (`force-app/...`). Avoid temporary copy paths because local source tracking can become corrupted with unsafe filepaths.
- For current known deployment/publish issues and proven workarounds, check `references/known-issues.md` first.

### Safety Checks Before Retrying Publish

- Confirm org alias and user:
  - `sf org display --target-org my-org-butler_DEV`
- Confirm bundle validates:
  - `sf agent validate authoring-bundle --api-name MyOrgButler --target-org my-org-butler_DEV`
- If source tracking looks corrupted (unsafe tmp filepath errors), apply the workaround documented in `references/known-issues.md`.
