# Implement Fix

## General

Write the fix for a GitHub issue in a Salesforce DX project.

**What you may touch:**

- `force-app/main/default/classes/` — Apex classes and test classes
- `force-app/main/default/lwc/` — Lightning Web Components

**What you must NOT touch:**

- Agentforce metadata, bot definitions, agent-eval specs
- Scratch org definition, sfdx-project.json, package.json
- Workflows, scripts, CLAUDE.md
- Flows, Permission Sets, Custom Metadata

If the fix requires any of the above: comment on the issue explaining why, add label `needs-human`, stop. Do not push anything.

**Apex rules:**

- SOQL must use bind variables — no string concatenation in queries
- DML outside loops — bulkify everything
- Follow the patterns already used in surrounding code — read adjacent classes first
- After writing code, mentally check against the project's coding standards in CLAUDE.md

**Steps:**

1. Create branch: `git checkout -b ai/issue-<number>`
2. Read the issue. Find the responsible class or component.
3. Read the affected file(s) in full before changing anything.
4. Write the fix and update or create the test class.
5. Commit: `git add <files> && git commit -m "fix: <short description> (closes #<number>)"`
6. Push: `git push origin ai/issue-<number>`
7. Stop. Do NOT open a PR — the workflow handles that after tests pass.

## This Project (My Org Butler)

**Additional constraints:**

- Never deploy with `sf project deploy start --source-dir force-app` (full deploy always fails due to namespace references)
- Never modify anything under `unpackaged/` — that contains the live agent definition
- Never modify `genAiFunctions`, `genAiPromptTemplates`, `genAiPlugins`, `genAiPlannerBundles`

**Test class rules:**

- No `@TestSetup` — each test method sets up its own data via a `setup()` helper
- No `seeAllData=true`
- Minimum 85% coverage
- Test method names: no `test` prefix, name describes the scenario
