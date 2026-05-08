---
name: sf-ticket-to-pr
description: Turn human words (a GitHub issue or a reviewer comment) into a tested, committed, and PR'd code change
---

# SF Ticket to PR

Human words come in (a freshly opened issue, or a reviewer's comment on an
existing PR). You turn them into committed code on a branch — opening a PR
if none exists yet, otherwise pushing to the existing one.

You are done when **either**:
- A new commit lands on a branch with an open PR (and `gh pr create` ran if
  the PR didn't exist before), **or**
- A clear stop-reason has been posted as a comment explaining why you can't.

## Preconditions (already done by the workflow)

- The correct branch is already checked out:
  - For new issues: a fresh `fix/issue-<N>` branch off `main`
  - For PR feedback: the PR's existing branch
- A scratch org is ready and set as default:
  - On the **first** run for an issue: freshly provisioned, source deployed, baseline Apex tests passing.
  - On every **subsequent** run on the same PR: the same scratch org from before, restored from cached auth — **do not** re-provision or re-deploy everything; only deploy files you actually changed.
- DevHub auth and SF CLI are ready.
- A Claude Bot GitHub App installation token is wired so `git push` and `gh pr create` are attributed to `claude-bot[bot]`.

## Step 1 — Triage

Before touching any code, post a triage comment **and** apply one of three labels.
Pick exactly one exit: **Acknowledge**, **Reject**, or **Split**. Then either continue
(Acknowledge only) or stop.

### Scope self-check

Answer these to yourself before picking Acknowledge:

- How many Apex classes will I touch? (1 = fine, 2-3 = borderline, 4+ = split)
- How many test classes new or changed?
- Does the work cross subsystems? (e.g. a new action **and** a new prompt template
  **and** a memory write = yes)

If two or more answers land in "borderline / yes", take the **Split** exit.

### Exit A — Acknowledge

The issue is clear, in-scope, and finishable in one run.

    gh issue comment <N> --body "I can do this in one run. Plan:
    - <bullet 1 — name a concrete class>
    - <bullet 2>
    - <bullet 3>
    Starting now."
    gh issue edit <N> --add-label ai-acknowledged

Then continue to Step 2.

### Exit B — Reject

Any of these is true:

- Schema changes needed (fields, objects, relationships)
- Flows, Permission Sets, Custom Metadata, or anything in `unpackaged/`
- Repro steps / feedback too vague to act on
- Cross-component architectural decision required
- Data Cloud, External Services, Named Credentials, or `config/`/`sfdx-project.json` changes
- The feedback contradicts the original issue or the existing change

    gh issue comment <N> --body "I can't do this. Reason: <one of the conditions above, named explicitly>. Missing: <what a human needs to do or decide>."
    gh issue edit <N> --add-label ai-rejected

Stop. Do not proceed to Step 2.

### Exit C — Split

The story is implementable but too big for one run (self-check failed).

    gh issue comment <N> --body "This is bigger than one run. Proposed split:
    - <sub-issue 1, scoped to ~1 class + tests>
    - <sub-issue 2>
    Stopping; please open the sub-issues and re-delegate."
    gh issue edit <N> --add-label ai-needs-split

Stop. Do not proceed to Step 2.

### For PR feedback

Same three exits, substitute `gh pr comment <PR>` and `gh pr edit <PR> --add-label`.
The label names are the same.

## Step 2 — Code

Touch whatever the change actually requires — classes, LWC, agent metadata
(`genAiFunctions/`, `genAiPlugins/`, `genAiPromptTemplates/`), permission sets,
Testing Center XML, anything else under `force-app/`. The triage in Step 1
is what protects against scope creep, not a folder allowlist.

Apex / coding rules live in `CLAUDE.md` and `rules/salesforce/coding-standards.md` — follow them.

Read each file you will change in full before editing. Then write the change
and update or add the test class.

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

## Step 4 — Ship

Commit and push:

    git add force-app/main/default/classes/<changed files>
    git commit -m "<one short sentence describing the change>"
    git push

### Always include the scratch org URL

Every PR description and every reply to a human reviewer **must** include a clickable
auto-login URL to the persistent scratch org so reviewers can manually test the change:

    SCRATCH_URL=$(sf org open --url-only --target-org "$SCRATCH_ORG_ALIAS" --json | jq -r .result.url)

(`SCRATCH_ORG_ALIAS` is set by the workflow to `pr-<issue-number>`.)

### Opening a new PR

If a PR for the current branch does **not** yet exist, open one. The body must be
specific enough that a reviewer can act without re-reading the issue — but no wall
of text. Aim for ~5–10 lines: what changed, how to verify, the scratch org URL,
the issue link.

    BRANCH=$(git branch --show-current)
    if [ -z "$(gh pr list --head "$BRANCH" --json number --jq '.[0].number')" ]; then
      gh pr create \
        --title "fix: <short description>" \
        --body "$(cat <<EOF
    Closes #<issue-number>

    ## What changed
    <2–4 bullets — what classes/methods were modified and why>

    ## How to verify
    - Open the scratch org: $SCRATCH_URL
    - <one or two concrete steps a human can run in the org>
    - Apex tests: \`sf apex run test --test-level RunLocalTests\`
    EOF
    )" \
        --head "$BRANCH" \
        --base main \
        --label ai-generated
    fi

If the PR already exists, the push above updates it — no new PR. When you reply
to feedback with `gh pr comment`, include `$SCRATCH_URL` in the comment body too.

### Stop here

Once the push has succeeded **and** the summary comment has been posted, **stop**.
Do not run further `gh pr view`, `git status`, `git log`, or other verification
commands to "double-check" — the work is done, and additional turns burn the budget
without changing the outcome.

## Anti-patterns

- Skipping Step 1 — touching code before posting the triage comment and applying a label.
- Acknowledging without naming concrete classes in the plan ("I'll add the action" is not a plan).
- Treating the scope self-check as advisory — if two answers say borderline/yes, split.
- Opening a second PR when one already exists for the branch.
- Investigating PMD findings on lines you did not touch.
- Calling `create-scratch-org.sh` — the workflow already restored or provisioned the org.
- Re-deploying everything via `--source-dir force-app` on a feedback run — only deploy the files you changed.
- Posting a PR description or reviewer reply without the scratch org auto-login URL.
- Stopping after a green test run without `git push`.
- Continuing to run verification commands after the push and summary comment — that's the post-completion loop, exit instead.
