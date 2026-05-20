---
name: sf-ticket-to-pr
description: Respond to @butler mentions on GitHub issues and PRs — read the thread, decide, act
---

# SF Ticket to PR

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

## Project-specific addenda

This skill is meant to be portable across any sfdx repo. Project-specific
rules — refuse-list additions, namespace handling, repo-specific deploy
commands — live in the consuming repo's `CLAUDE.md`. Read that file alongside
this one and treat its rules as overrides where they conflict.

## Step 1 — Read the thread, then decide

Before touching code, read the conversation:

    gh issue view <N> --repo <owner/repo> --comments     # for issues
    gh pr view  <N> --repo <owner/repo> --comments       # for PRs

You will already have been given the kind (`issue` or `pr`) and number `<N>`
in the prompt. Read everything — the body and every comment, in order. The
latest human signal is authoritative; if a maintainer's most recent comment
contradicts an earlier one of yours, follow the maintainer.

**Verify any prior bot promises before believing them.** Earlier bot
comments may say "Done — PR #X" or "I'll attach to PR #Y" or "branch
fix/issue-N has the change". Those statements were true at the time but
may not be true now (PR closed, branch deleted, work reverted). Before
adopting any plan that depends on prior bot output, **check current
state**:

    gh pr view <N> --repo <owner/repo> --json state,headRefName 2>&1
    git ls-remote --heads origin <branch-name>

If the referenced PR is closed or its branch is gone, the work is **not
done**. Treat the latest maintainer mention as a fresh ask: re-implement
from scratch on a new branch off `main`, open a new PR. Do not waste a
turn trying to update a deleted PR.

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

**Verification plan (pick what fits, not all of them).** Apex / triggers
touched → Apex tests. Agentforce metadata touched (`genAi*`, `bots/`) → a
Testing Center case in `aiEvaluationDefinitions/`. User-visible change
(Flow, Lightning page, LWC, screen flow) → a Playwright scenario via the
`playwright-sf` skill with screenshots. **Interactive conversational UI** (any surface where a user types and the system responds) → a Playwright **video** via the Node.js recipe in `playwright-sf` — not just screenshots, because the full turn (user input → system processes → response appears) is what needs to be shown. **If the ticket is
a bug**, first reproduce it in the org with `playwright-sf` and attach the
repro screenshot to your plan comment. Apex-only refactors don't need UI
checks. Pick the cheapest verification that proves the requirement.

**The plan is what YOU, the agent, will verify — not a checklist for the
human.** The PR must never contain "How to verify" instructions telling the
reviewer to log in, activate pages, create records, click around. You do
all of that yourself in Step 3 and attach the evidence (screenshots, SOQL
output, test results). The reviewer's only verification is glancing at the
evidence and optionally clicking the scratch-org URL.

**If your change creates a custom Lightning record page (FlexiPage), you
also activate it** — as Org Default for the relevant `sObjectType`, or
assigned to the appropriate app/profile. A non-activated page is invisible
to users, so shipping one is the same as shipping nothing. Verification
without activation is impossible because the new page is never rendered.


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

- `config/`, `sfdx-project.json`, or `.github/workflows/` changes — these belong in a separate human PR for safety.
- Feedback that contradicts the original issue without explanation — ask for clarification instead of guessing.
- Anything listed in the consuming repo's `CLAUDE.md` refuse-list addendum.

Comment with the reason in one sentence. **Do not** include the proceed
marker. Stop.

## Step 2 — Code

Touch whatever the change actually requires — classes, LWC, agent metadata
(`genAiFunctions/`, `genAiPlugins/`, `genAiPromptTemplates/`), permission sets,
queues, custom fields, Flows, Testing Center XML, anything else under
`force-app/` or `unpackaged/`. The triage in Step 1 is what protects against
scope creep, not a folder allowlist.

Apex / coding rules live in the consuming repo's `CLAUDE.md` and any
`rules/` files it references — follow them. Repo-specific deploy gotchas
(namespace stripping, Agentforce-specific fixups, etc.) also belong in
`CLAUDE.md` — read it alongside this skill.

Read each file you will change in full before editing. Then write the change
and update or add the test class.

## Step 3 — Verify

Redeploy the changed file (the script already deployed everything else):

    sf project deploy start --source-dir force-app/main/default/classes/<File>.cls --concise

If the consuming repo's `CLAUDE.md` describes a namespace strip-deploy-restore
dance or other pre-deploy massaging, follow that instead.

Run tests **in the foreground** with a Bash timeout long enough to cover the full Apex run (the CLI `--wait 30` is 30 minutes — the Bash timeout must match):

    sf apex run test --test-level RunLocalTests --wait 30 --result-format human

Do **not** background this call and poll `TaskOutput` — the 5-minute `TaskOutput` cap is shorter than a real test run, the agent will read "still running" and stall the PR. Use Bash `timeout: 1800000` (30 min) and let the CLI print results directly when finished.

Run the `/sf-code-analyzer` skill on the files you changed. Use the
selectors the consuming repo's setup configures (typically via
`code-analyzer.yaml` at the repo root). Fix every new finding the agent
caused, on the lines you touched.

**Scope discipline:** the analyzer reports findings on the whole file, but you
own only the lines you touched. Findings on lines you did not change are
pre-existing — ignore them. Do not investigate or fix them.

Repeat until tests pass and the analyzer reports no new findings on lines
you touched.

If your plan included a Playwright scenario (bug repro or UI verification),
invoke the `playwright-sf` skill to run it now against the scratch org.
Attach the resulting screenshots to the PR body in Step 4. A `UI-FAIL`
result means the change is wrong — iterate. A `UI-INCONCLUSIVE` result
means the assertion couldn't load reliably — note it in the PR but don't
block on it.

## Step 4 — Ship

Commit and push:

    git add force-app/main/default/classes/<changed files>
    git commit -m "<one short sentence describing the change>"
    git push

### Always include the scratch org URL — non-negotiable

Every "I implemented this" surface — the PR body, every reply to a reviewer,
the post-execution summary comment — **must** include a clickable auto-login
URL to the per-PR scratch org. Reviewers should be able to click through and
poke at the change themselves without re-deploying anything. The scratch org
is throwaway, so the URL is safe to post in a public repo.

    SCRATCH_URL=$(sf org open --url-only --target-org "$SCRATCH_ORG_ALIAS" --json | jq -r .result.url)

(`SCRATCH_ORG_ALIAS` is set by the workflow to `pr-<issue-number>`.)

If you also produced Playwright screenshots, embed them inline in the same
markdown body — `playwright-sf` writes them under a path you can commit to
the branch so GitHub renders them by relative URL. The pair "here's a
screenshot of it working / here's the org if you want to see for yourself"
is what makes the PR self-evidencing.

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

    ## Verified
    <what you, the agent, verified — Apex test counts, Playwright screenshots
    embedded inline by relative path, SOQL excerpts. Do NOT write instructions
    for a human to follow; the only human verification is clicking the scratch
    URL below if curious.>

    Scratch org: <SCRATCH_URL>
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
