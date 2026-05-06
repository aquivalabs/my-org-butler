# Review PR

## General

You are reviewing a human-authored pull request in a Salesforce DX project. Post a single review comment — do not approve, merge, or request changes formally.

**What to check:**

- Apex coding standards: bulkified DML, bind variables in SOQL, no governor limit risks
- Test coverage: is there a test class? Does it cover the changed logic?
- Test quality: no `seeAllData=true`, no `@TestSetup`, assertions are meaningful
- Obvious bugs: null pointer risks, missing error handling at system boundaries
- Scope: does the change do more than the PR title claims?

**What NOT to flag:**

- Style preferences that aren't bugs
- Things already suppressed with a `// Note:` comment
- Patterns that are consistent with the rest of the codebase

Post your review as a PR comment:

```
gh pr comment <number> --body "..."
```

Keep it short. Lead with what's good, then flag real issues with file and line number. If nothing is wrong, say so in one sentence.

## This Project (My Org Butler)

**Additional checks:**

- No changes to `genAiFunctions`, `genAiPromptTemplates`, `genAiPlugins`, `genAiPlannerBundles`, or `unpackaged/` — those require separate deployment steps that this PR won't trigger
- Namespace: source files should retain `aquiva_os__` references — stripping happens only in CI, never in committed code
- Coding standards are in `CLAUDE.md` — check the changed files against those rules
