---
name: sf-ticket-to-pr
description: Turns a GitHub issue into a tested pull request — or comments on the issue explaining why it cannot be done autonomously
---

# SF Ticket to PR

A GitHub issue arrives. You ship a PR that fixes it, or you comment on the issue
explaining why you can't.

You are done **only** when `gh pr create` returns a URL, OR when
`gh issue comment` has posted a clear stop-reason. Anything else is incomplete.

## Preconditions (already done by the workflow before you start)

- Branch `ai/issue-<number>` is checked out — you're already on it.
- A scratch org is fully provisioned with all source deployed and Apex tests passing.
- DevHub auth and SF CLI are ready.

You only need to: read the affected file(s), write the fix, deploy + test it,
commit, push, and open the PR.

## Step 1 — Decide

Stop and comment if any of these are true:

- Schema changes needed (fields, objects, relationships)
- Flows, Permission Sets, Custom Metadata, or anything in `unpackaged/`
- Repro steps too vague to act on
- Cross-component architectural decision required
- Data Cloud, External Services, Named Credentials, or `config/`/`sfdx-project.json` changes

Stop format:

    gh issue comment <number> --body "<one paragraph: what is missing or what kind of change is needed>"

## Step 2 — Code

Touch only `force-app/main/default/classes/` and `force-app/main/default/lwc/`.
Apex / coding rules live in `CLAUDE.md` and `rules/salesforce/coding-standards.md` — follow them.

Read each file you will change in full before editing. Then write the fix and
update or add the test class.

## Step 3 — Verify

Redeploy the changed file (the script already deployed everything else):

    sed -i 's/aquiva_os__//g' force-app/main/default/classes/<File>.cls && \
      sf project deploy start --source-dir force-app/main/default/classes/<File>.cls --concise; \
      git checkout -- force-app/main/default/classes/<File>.cls

Run tests:

    sf apex run test --test-level RunLocalTests --wait 30 --result-format human

Run the analyzer on the file you changed:

    sf code-analyzer run --rule-selector "PMD:OpinionatedSalesforce" \
      --output-file /tmp/analyzer.csv \
      --target force-app/main/default/classes/<File>.cls

**Scope discipline:** the analyzer reports findings on the whole file, but you
own only the lines you touched. Findings on lines you did not change are
pre-existing — ignore them. Do not investigate or fix them.

Repeat until tests pass and the analyzer reports no new findings on lines
you touched.

## Step 4 — Ship (mandatory)

    git add force-app/main/default/classes/<changed files>
    git commit -m "fix: <short description> (closes #<number>)"
    git push origin ai/issue-<number>
    gh pr create \
      --title "fix: <short description>" \
      --body "Closes #<number>" \
      --head ai/issue-<number> \
      --base main

`gh pr create` returning a URL means you are done.

## Anti-patterns

- Investigating PMD findings on lines you did not touch.
- Calling `create-scratch-org.sh` — the workflow already provisioned the org.
- Stopping after a green test run without `git push` and `gh pr create`.
