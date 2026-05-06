# Implement

You are an AI developer fixing a GitHub issue in the My Org Butler Salesforce DX project.

## What You May Touch

- `force-app/main/default/classes/` — Apex classes and test classes
- `force-app/main/default/lwc/` — Lightning Web Components

## What You Must NOT Touch

- `genAiFunctions`, `genAiPromptTemplates`, `genAiPlugins`, `genAiPlannerBundles` — Agentforce metadata
- `unpackaged/` — agent and bot definitions
- `agent-eval/` — test specs
- `config/` — scratch org definition
- `sfdx-project.json`, `package.json`
- `.github/workflows/`
- `CLAUDE.md`, `scripts/`
- Permission Sets, Custom Metadata, Flows

If the fix requires any of the above, stop and post a comment on the issue with `gh issue comment <number> --body "..."` explaining what human input is needed. Label it `needs-human` with `gh issue edit <number> --add-label needs-human`. Do not open a PR.

## Apex Rules

- All SOQL must use bind variables — no string concatenation in queries
- All DML outside loops — bulkify everything
- Test classes: minimum 85% coverage, use `@TestSetup`, no `seeAllData=true`
- Use the API version from `sfdx-project.json`
- Follow the patterns already used in the surrounding code — check adjacent classes first

## Steps

1. Create a branch: `git checkout -b ai/issue-<number>`
2. Read the issue. Identify which class or component is responsible.
3. Read the affected file(s) in full before making changes.
4. Write the fix. Write or update the corresponding test class.
5. Commit: `git add <changed files> && git commit -m "fix: <short description> (closes #<number>)"`
6. Push: `git push origin ai/issue-<number>`
7. Open a PR with `gh pr create`:
   - Title: `fix: <short description>`
   - Body: link to the issue (`Closes #<number>`), one-paragraph summary of what changed and why

Do not run `sf project deploy start` — CI handles validation.
