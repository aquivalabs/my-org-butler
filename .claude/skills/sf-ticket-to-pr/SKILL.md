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

## Step 2 — Branch and fix

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

## Step 3 — Verify in scratch org (iterate until clean)

This step is a loop. Keep iterating until Apex tests pass AND the code analyzer is clean.

### 3a — Create scratch org

```bash
sf org create scratch \
  --alias ci-fix-<number> \
  --set-default \
  --definition-file ./config/project-scratch-def.json \
  --duration-days 1 \
  --no-namespace
```

### 3b — Strip namespace from source (Linux sed — no quotes after -i)

```bash
sed -i 's/aquiva_os__//g; s/aquiva_os\.//g; s/"namespace": "aquiva_os"/"namespace": ""/' sfdx-project.json
find force-app -type f \( -name "*.cls" -o -name "*.xml" \) \
  -exec sed -i 's/aquiva_os__//g; s/aquiva_os\.//g' {} +
```

### 3c — Deploy only the files you changed

Never deploy `--source-dir force-app`. List each file explicitly:

```bash
sf project deploy start \
  --source-dir force-app/main/default/classes/Foo.cls \
  --source-dir force-app/main/default/classes/Foo_Test.cls \
  --concise
```

If the deploy fails due to a compilation error, fix the code and redeploy.

### 3d — Run Apex tests

```bash
sf apex run test \
  --test-level RunLocalTests \
  --wait 30 \
  --code-coverage \
  --result-format human
```

If tests fail: read the failure output, fix the code, redeploy (3c), rerun tests (3d).

### 3e — Run code analyzer

```bash
sf code-analyzer run \
  --rule-selector "PMD:OpinionatedSalesforce" \
  --output-file /tmp/code-analyzer.csv \
  --target force-app/main/default/classes/<ChangedFile>.cls
```

Review `/tmp/code-analyzer.csv`. For each violation:
- Fix the code if it is a real issue
- If it is a false positive, suppress with a `// Note:` comment explaining why
- Redeploy (3c), rerun tests (3d), rerun analyzer (3e)

Repeat until `code-analyzer.csv` is empty or contains only known acceptable suppressions.

### 3f — Restore source and delete scratch org

```bash
git checkout -- sfdx-project.json force-app/
sf org delete scratch --no-prompt --target-org ci-fix-<number>
```

## Step 4 — Open the PR

```bash
git add force-app/main/default/classes/<changed files>
git commit -m "fix: <short description> (closes #<number>)"
git push origin ai/issue-<number>
```

```bash
gh pr create \
  --title "fix: <short description>" \
  --body "Closes #<number>" \
  --head ai/issue-<number> \
  --base main
```
