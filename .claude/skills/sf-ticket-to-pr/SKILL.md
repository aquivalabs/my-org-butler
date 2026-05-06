---
name: sf-ticket-to-pr
description: Turns a GitHub issue into a tested pull request — or comments on the issue explaining why it cannot be done autonomously
---

# SF Ticket to PR

You receive a GitHub issue. You either open a PR that fixes it, or you comment on the issue explaining precisely why you cannot.

## Step 1 — Decide

Can this issue be solved by changing Apex or LWC source code only?

**Stop and comment if any of these are true:**

General blockers:
- Requires schema changes (fields, objects, relationships)
- Requires Flows, Permission Sets, or Custom Metadata changes
- Reproduction steps are missing or too vague to act on
- Requires architectural decisions across many components

This project (My Org Butler) blockers:
- Requires changes to Agentforce metadata: `genAiFunctions`, `genAiPromptTemplates`, `genAiPlugins`, `genAiPlannerBundles`, or bot definitions in `unpackaged/`
- Requires Data Cloud configuration changes
- Requires External Services or Named Credentials changes
- Requires changes to `config/project-scratch-def.json` or `sfdx-project.json`

If stopping, post a comment that says exactly what is missing or what type of change is needed:
```
gh issue comment <number> --body "..."
```

## Step 2 — Write the code

**What you may touch:** `force-app/main/default/classes/`, `force-app/main/default/lwc/`

**What you must NOT touch:** anything in `unpackaged/`, `agent-eval/`, `config/`, `scripts/`, `.github/`, `CLAUDE.md`, `sfdx-project.json`

Apex rules:
- SOQL must use bind variables — no string concatenation in queries
- DML outside loops
- Read adjacent classes before writing — follow existing patterns
- No `@TestSetup` — each test sets up its own data via a `setup()` helper
- No `seeAllData=true`, minimum 85% coverage
- Test method names: no `test` prefix

Steps:
1. `git checkout -b ai/issue-<number>`
2. Read the affected file(s) in full before changing anything
3. Write the fix and update or create the test class
4. `git add <files> && git commit -m "fix: <short description> (closes #<number>)"`
5. `git push origin ai/issue-<number>`

## Step 3 — Open the PR

```
gh pr create \
  --title "fix: <short description>" \
  --body "Closes #<number>" \
  --head ai/issue-<number> \
  --base main
```
