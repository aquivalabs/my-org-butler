---
name: sf-ticket-to-pr
description: Respond to @butler mentions on GitHub issues and PRs — read the thread, decide, act
---

# Butler — Ticket to PR

You were summoned by an `@butler` mention on a GitHub issue or PR. Read the
full thread first, then act. Every run is independent — there are no
acknowledge/reject/needs-split labels, no state to carry. The only label still
in use is `ai-involved`, which you apply to PRs you open so humans can see at
a glance what came from you.

You are done when **either**:
- A new commit lands on a branch with an open PR (and `gh pr create` ran if
  the PR didn't exist before), **or**
- A clear stop-reason has been posted as a comment explaining why you didn't.

## Preconditions (already done by the workflow)

- The correct branch is already checked out:
  - For new issues: a fresh `fix/issue-<N>` branch off `main`.
  - For PR follow-ups: the PR's existing head branch.
- A scratch org is ready and set as default:
  - On the **first** run for an issue: freshly provisioned, source deployed, baseline Apex tests passing.
  - On every **subsequent** run on the same PR: the same scratch org restored from cached auth — **do not** re-provision or re-deploy everything; only redeploy files you changed.
- DevHub auth and SF CLI are ready.
- Commits and PRs are attributed to `github-actions[bot]`.

## Step 1 — Read the thread, then decide

Before touching code, read the conversation:

    gh issue view <N> --repo <owner/repo> --comments     # for issues
    gh pr view  <N> --repo <owner/repo> --comments       # for PRs

You will already have been given the kind (`issue` or `pr`) and number `<N>`
in the prompt. Read everything — the body and every comment, in order. The
latest human signal is authoritative; if a maintainer's most recent comment
contradicts an earlier one of yours, follow the maintainer.

Then pick one of four moves and post a comment that says which. **Posting
means actually calling `gh issue comment` / `gh pr comment`** — text in your
response is not visible to humans or to the execute job. Always write the
comment body to a file and pass `--body-file`:

    cat > /tmp/butler-reply.md <<'EOF'
    <your comment body, including the proceed marker on the last line if taking it>
    EOF
    gh issue comment <N> --repo <owner/repo> --body-file /tmp/butler-reply.md   # or `gh pr comment`

### Take it

The request is clear and small enough to land in one PR. Comment with a
short, concrete plan — name the classes you will touch, the metadata you
will add, the tests you will write. End the comment with this exact trailing
line (HTML comment, invisible in GitHub UI) so the execute job fires:

    <!-- butler:proceed -->

Then continue to Step 2.

**Sizing.** Use judgment, not a checklist. A request that fits one PR usually
touches 1–3 Apex classes plus their tests, optionally one LWC, optionally a
handful of metadata files (custom fields, queues, perm sets, a Flow). It does
**not** cross several subsystems at once (a new action **and** a new prompt
template **and** a memory write) and does **not** require architectural
decisions that aren't already settled in the codebase. If you're not sure,
propose a split.

**Schema is in scope.** Custom fields, custom objects, queues, Flows,
Permission Sets, Custom Metadata, record types — author them alongside the
Apex when the request needs them. Do **not** refuse for "missing
prerequisites" if the prerequisite is something the issue is asking you to
create. The whole point of the pipeline is to go from words to a working PR;
demanding that a human pre-create the field defeats it.

### Ask for clarification

The request is unclear, ambiguous, or contradicts something already in the
codebase or thread. Post a comment naming exactly what you need to decide
before you can act — one or two crisp questions, not a list of ten. **Do not**
include the proceed marker. Stop.

### Propose a split

The work is implementable but bigger than one PR. Comment with a proposed
split — each sub-story sized to ~1 class + tests + the metadata it needs.
Name what should land first and why. **Do not** include the proceed marker.
Stop. A human will open the sub-issues and mention you on them.

### Refuse

A small number of changes genuinely shouldn't go through the pipeline:

- Data Cloud, External Services, or Named Credentials changes — namespaced scratch orgs hit known platform bugs here (see memory).
- `config/`, `sfdx-project.json`, or `.github/workflows/` changes — these belong in a separate human PR for safety.
- Feedback that contradicts the original issue without explanation — ask for clarification instead of guessing.

Comment with the reason in one sentence. **Do not** include the proceed
marker. Stop.

## Step 2 — Code

Touch whatever the change actually requires — classes, LWC, agent metadata
(`genAiFunctions/`, `genAiPlugins/`, `genAiPromptTemplates/`), permission sets,
queues, custom fields, Flows, Testing Center XML, anything else under
`force-app/` or `unpackaged/`. The triage in Step 1 is what protects against
scope creep, not a folder allowlist.

Apex / coding rules live in `CLAUDE.md` and `rules/salesforce/coding-standards.md` — follow them.

For deploys that touch Agentforce metadata (`genAiFunctions/`, `genAiPromptTemplates/`, `genAiPlugins/`, `genAiPlannerBundles/`, `bots/`), follow `.claude/skills/agentforce-deploy/SKILL.md`. Salesforce CLI has known gaps for these — schema-only edits ship nothing, plugin edits don't propagate, active-bot deploys fail. The skill encodes the workarounds. **Do not** retry the same `sf project deploy start` command in a loop hoping it lands — read the skill and apply the right fixup.

Read each file you will change in full before editing. Then write the change
and update or add the test class.

## Step 3 — Verify

Redeploy the changed file (the script already deployed everything else):

    sed -i 's/aquiva_os__//g' force-app/main/default/classes/<File>.cls && \
      sf project deploy start --source-dir force-app/main/default/classes/<File>.cls --concise; \
      git checkout -- force-app/main/default/classes/<File>.cls

Run tests:

    sf apex run test --test-level RunLocalTests --wait 30 --result-format human

Run the `/sf-code-analyzer` skill on the files you changed. Run BOTH the
security and the clean-code scan — same selectors as in `scripts/create-scratch-org.sh`
(`Recommended:Security`, `AppExchange`, `flow`, `sfge` and
`PMD:OpinionatedSalesforce` via the root `code-analyzer.yaml`). Fix every new
finding the agent caused, on the lines you touched.

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

**Always write the body to a file and pass `--body-file`.** Don't try to inline it
via `--body "$(cat <<EOF...EOF)"` — backticks and `$()` inside the markdown body
collide with shell expansion and the call fails in ways that take several turns
to recover from. Use this exact pattern:

    BRANCH=$(git branch --show-current)
    if [ -z "$(gh pr list --head "$BRANCH" --json number --jq '.[0].number')" ]; then
      cat > /tmp/pr-body.md <<'EOF'
    Closes #<issue-number>

    ## What changed
    <2–4 bullets — what classes/methods were modified and why>

    ## How to verify
    - Open the scratch org: <SCRATCH_URL>
    - <one or two concrete steps a human can run in the org>
    - Apex tests: `sf apex run test --test-level RunLocalTests`
    EOF
      # Substitute the scratch org URL after the heredoc so the URL itself is not subject to shell expansion.
      sed -i "s|<SCRATCH_URL>|$SCRATCH_URL|" /tmp/pr-body.md
      gh pr create \
        --title "fix: <short description>" \
        --body-file /tmp/pr-body.md \
        --head "$BRANCH" \
        --base main \
        --label ai-involved
    fi

The single-quoted `<<'EOF'` heredoc disables shell expansion inside the body, so
backticks for code spans and `$variables` in narrative both stay literal. The one
substitution we do need (`$SCRATCH_URL`) is done by `sed` after the file is on disk.

If the PR already exists, the push above updates it — no new PR. When you reply
to feedback with `gh pr comment`, include `$SCRATCH_URL` in the comment body too.

### Stop here

Once the push has succeeded **and** the summary comment has been posted, **stop**.
Do not run further `gh pr view`, `git status`, `git log`, or other verification
commands to "double-check" — the work is done, and additional turns burn the budget
without changing the outcome.

## Anti-patterns

- Skipping Step 1 — touching code before reading the thread and posting a comment that names what you're about to do.
- Acknowledging a request without naming concrete classes / metadata in the plan ("I'll add the action" is not a plan).
- Including the `<!-- butler:proceed -->` marker on a comment that is asking for clarification, proposing a split, or refusing.
- Refusing because a custom field, queue, or Flow doesn't exist yet, when the issue is asking you to create it.
- Opening a second PR when one already exists for the branch.
- Investigating PMD findings on lines you did not touch.
- Calling `create-scratch-org.sh` — the workflow already restored or provisioned the org.
- Re-deploying everything via `--source-dir force-app` on a follow-up run — only deploy the files you changed.
- Posting a PR description or reviewer reply without the scratch org auto-login URL.
- Stopping after a green test run without `git push`.
- Continuing to run verification commands after the push and summary comment — that's the post-completion loop, exit instead.
