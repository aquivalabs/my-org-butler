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

## Step 3 — Verify in scratch org

### 3a — Create and provision the scratch org

Use the same script humans use, in headless mode:

```bash
HEADLESS=true ./scripts/create-scratch-org.sh
```

This creates the scratch org, deploys `force-app` + `unpackaged` + `agent-eval` (with namespace stripping), assigns permsets, activates the agent, creates sample data, and runs all Apex tests. It skips the manual setup, Data Library wait, and Regression suite — those need a human and aren't useful here.

If the script fails, read the error, fix the code, and re-run only what's needed (don't rebuild the org from scratch — see 3b).

### 3b — Iterate (deploy → test → analyze → fix)

After the script completes, the source is back to its namespaced form. To redeploy a single changed file:

```bash
# Strip namespace, deploy, restore
sed -i 's/aquiva_os__//g; s/aquiva_os\.//g' force-app/main/default/classes/<ChangedFile>.cls
sf project deploy start --source-dir force-app/main/default/classes/<ChangedFile>.cls --concise
git checkout -- force-app/main/default/classes/<ChangedFile>.cls
```

Then run tests:

```bash
sf apex run test --test-level RunLocalTests --wait 30 --code-coverage --result-format human
```

Then run the code analyzer on the changed file:

```bash
sf code-analyzer run \
  --rule-selector "PMD:OpinionatedSalesforce" \
  --output-file /tmp/code-analyzer.csv \
  --target force-app/main/default/classes/<ChangedFile>.cls
```

For each violation in `/tmp/code-analyzer.csv`:
- Real issue → fix the code
- False positive → suppress with `@SuppressWarnings(...)` and a `// Note:` comment explaining why

Repeat until tests pass AND the analyzer is clean.

### 3c — Tear down

```bash
sf org delete scratch --no-prompt --target-org my-org-butler_DEV
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
