---
name: agentforce
description: Write and edit Salesforce Agentforce Agent Script (.agent files). Use when creating agents, editing agent topics, writing reasoning instructions, defining actions, configuring variables, or troubleshooting Agent Script syntax. Covers the full Agent Script DSL including config, system, variables, start_agent, topic blocks, actions, tools, transitions, conditionals, lifecycle hooks, and template expressions.
---

# Agent Script

Write and troubleshoot Salesforce Agentforce agents using Agent Script — a YAML-like DSL for hybrid reasoning.

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
| `@utils.set_variable` | LLM slot-fills a variable |
| `@utils.escalate` | Hand off to human |
| `@outputs.x` | Action output (after `run` / in `set`) |
| `run` | Execute action deterministically |
| `set` | Store value in variable |
| `with` | Bind input parameter |
| `...` | LLM slot-fill (asks user, fills value) |
| `if / else if / else` | Conditional branching |
| `available when` | Guard clause for tools |
| `#` | Comment |

## Three Ways to Run Actions

1. **`run @actions.x` in `->` block** — 100% deterministic, always executes
2. **`{!@actions.x}` in `|` block** — suggestion, LLM decides
3. **`reasoning.actions` block** — LLM picks from toolbox

## Topic Navigation

- `transition to @topic.x` / `@utils.transition to` → **one-way**, no return
- `@topic.x` as reasoning action → **delegation**, returns to caller after completion

## File Conventions

- Indentation: 3 spaces (mandatory)
- Names: `snake_case`, letters/numbers/underscores, start with letter, max 80 chars
- Block order: `config → system → language → connection → variables → start_agent → topic(s)`

## Detailed Reference

Read `references/agent-script-guide.md` for the full condensed language reference covering all blocks, variable types, action definitions, input bindings, lifecycle hooks, guard clauses, and complete working examples.

## Known Issues & Quirks

When you encounter unexpected behavior, deployment failures, or runtime errors — check `references/known-issues.md` first. It tracks bugs and quirks in Agent Script beta. If you discover a new issue, add it to that file.

## Verification Protocol

When something fails, is ambiguous, or the user questions output — **do not guess**. Fetch the relevant canonical URL from `references/official-sources.md` and verify before retrying.

Specific triggers to fetch official docs:
- **Compilation/deployment error** → Fetch Blocks reference + specific element reference
- **Action not executing** → Fetch Actions reference AND Tools reference (different invocation methods)
- **Variable not updating** → Fetch Variables reference (mutable vs immutable, linked vs regular)
- **Topic transition wrong** → Fetch Utils + Tools reference (transition vs delegation)
- **New/unfamiliar syntax** → Fetch main Agent Script overview page first
- **User contradicts the local guide** → Trust official docs; update local guide if needed

If a doc URL 404s, web-search `site:developer.salesforce.com agent script <topic>` as fallback.

## Self-Improvement

This skill's reference files are editable. When you discover something during a session that improves your understanding, **update the references directly**:

- **Found an error in `references/agent-script-guide.md`?** Fix it in place. Add a comment noting the correction and source (e.g. `<!-- Corrected 2025-02: official docs say mutable is required for set -->`).
- **Official doc URL changed or 404'd?** Update the URL in `references/official-sources.md`.
- **Discovered a new pattern, gotcha, or undocumented behavior?** Append it to the relevant section in the guide. If it doesn't fit anywhere, add a `## Discovered Patterns` section at the bottom.
- **A recipe or example solved something tricky?** Add a minimal version to the guide's examples section.

Also use `/memory` or tell the user: "I learned something about Agent Script — want me to save it to memory?" so learnings persist across sessions even if the skill files aren't writable.

The goal: every session that hits an edge case makes the next session smarter.

## Common Mistakes to Catch

- Forgetting `mutable` on variables the agent needs to change
- Using `transition to` when they want delegation (one-way vs returns)
- Putting `run` statements inside `|` blocks (logic must follow `->`, not inside prompts)
- Using `...` (slot-fill) in chained action inputs (only works for top-level inputs)
- Missing `description` on reasoning actions (LLM needs this to choose tools)
- Referencing actions across topics (actions are topic-scoped)

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
