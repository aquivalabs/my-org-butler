# SF Ticket-to-PR Pipeline — Setup Guide

This folder ships an AI-driven pipeline: a developer opens a GitHub issue, an
agent reads it, decides if it's solvable as Apex/LWC code, provisions a fresh
scratch org, writes the fix, runs tests, and opens a pull request with the
`ai-generated` label. A reviewer's comment on that PR triggers another run that
applies the requested change. Humans only review and merge — no AI auto-merge.

This document is for engineers in other Aquiva repos who want to take the
pipeline over. It explains **what to copy**, **what to set up once**, and
**how to adapt it to your own project**.

## What you get

Two workflows that share one skill:

| File | Trigger | What it does |
|---|---|---|
| `sf-ticket-to-pr.yml` | issue opened (or `workflow_dispatch`) | Creates branch `fix/issue-<N>`, provisions scratch org, runs Claude, opens PR with `ai-generated` label, reports AI spend. |
| `sf-pr-feedback.yml` | comment on a PR carrying the `ai-generated` label | Checks out the PR branch, provisions a fresh scratch org, runs Claude on the comment text, pushes to the branch, reports AI spend. |

The pipeline does the deterministic work (git checkout, SF CLI install, DevHub
auth, scratch org provisioning); Claude is only asked to write code. Both
workflows invoke the same skill at `.claude/skills/sf-ticket-to-pr/SKILL.md`.

## Files to copy into your repo

```
.github/workflows/sf-ticket-to-pr.yml
.github/workflows/sf-pr-feedback.yml
.claude/skills/sf-ticket-to-pr/SKILL.md
.claude/settings.json                       # allow-list for tools Claude may run
scripts/snapshot-jsonl.sh                   # for AI-cost reporting
scripts/report-ai-cost.sh                   # for AI-cost reporting
scripts/create-scratch-org.sh               # Salesforce-specific; you may already have one
```

Adjust the `create-scratch-org.sh` to your own provisioning needs. The
contract is: **`HEADLESS=true ./scripts/create-scratch-org.sh` must exit 0
when the org is ready** — no manual prompts, no `sf org open`, no
human-gated waits. Everything else (deploy, permsets, sample data, baseline
tests) stays the same as your manual setup.

## One-time setup per repository

### 1. Create the "Claude Bot" GitHub App

The pipeline pushes branches that contain workflow files. The default
`GITHUB_TOKEN` cannot do that — GitHub blocks it for security reasons,
regardless of the `permissions:` block. A GitHub App with the `workflows`
permission is the canonical fix. Using an App (instead of a personal access
token) also keeps PR/commit/comment authorship attributed to a bot user
(`claude-bot[bot]`), so the human reviewer remains eligible to approve the PR.

Create the App once for the org (it can be reused across all repos):

1. **Settings → Developer settings → GitHub Apps → New GitHub App**.
2. Name: `Claude Bot` (or similar). Disable Webhooks.
3. **Repository permissions:**
   - Contents: Read and write
   - Issues: Read and write
   - Pull requests: Read and write
   - Workflows: Read and write
   - Metadata: Read (auto)
4. **Where can this GitHub App be installed?** Only on this account.
5. Save, then **Install** the App on your repo.
6. **Generate a private key** (PEM file). You'll paste this into the
   `CLAUDE_BOT_PRIVATE_KEY` secret below.
7. Note the **App ID** (visible on the App's settings page).

### 2. Set the repository secrets

In **Settings → Secrets and variables → Actions**, add:

| Secret | What goes in |
|---|---|
| `CLAUDE_BOT_APP_ID` | The numeric App ID from step 1.7. |
| `CLAUDE_BOT_PRIVATE_KEY` | The full contents of the PEM file from step 1.6. Include the `BEGIN`/`END` lines. |
| `SFDX_AUTH_URL` | The DevHub's auth URL: `sf org display --verbose --target-org <devhub-alias> --json \| jq -r '.result.sfdxAuthUrl'`. |
| `ANTHROPIC_API_KEY` | Anthropic API key, **or** use `CLAUDE_CODE_OAUTH_TOKEN`. The action accepts either. |
| `CLAUDE_CODE_OAUTH_TOKEN` | Optional alternative to `ANTHROPIC_API_KEY` — uses an Anthropic Max subscription. |

**Never** commit any of these values to the repo or paste them into chat. The
workflows reference them by name only.

### 3. Create the `ai-generated` label

```bash
gh label create ai-generated \
  --description "Pull request opened by the SF ticket-to-PR pipeline" \
  --color FBCA04
```

The PR-feedback workflow filters on this label, and the issue workflow's
SKILL applies it on `gh pr create`.

### 4. Project rules and tool allow-list

The skill defers project-specific Apex/LWC rules to your repo's
`CLAUDE.md` and `rules/salesforce/coding-standards.md`. Make sure both
exist with conventions you want enforced.

`.claude/settings.json` lists the bash commands Claude is allowed to run.
Review and trim it for your repo if needed — only add what's required.

## What a typical run looks like

1. You open issue #42 with a clear repro and a code-only fix.
2. The `SF Ticket to PR` workflow fires automatically.
3. It checks out the repo as `claude-bot[bot]`, installs SF CLI,
   authenticates to DevHub, creates branch `fix/issue-42`, runs
   `create-scratch-org.sh`.
4. Claude reads the issue, edits the affected file(s), redeploys the single
   changed file to the scratch org, runs Apex tests, runs the code analyzer
   scoped to the changed file, iterates until clean.
5. Claude opens a PR with `ai-generated` label.
6. The workflow's last step verifies the PR exists and appends an AI-spend
   footer (cost, tokens, model) to the PR body. It also maintains a sticky
   rollup comment on the originating issue.
7. You review the PR. If something needs to change, you comment in plain
   prose — no `@claude` mention required. The `SF PR Feedback` workflow
   fires, provisions a fresh scratch org, Claude applies the change and
   pushes back to the same branch.
8. You merge when ready.

## What to watch for

- **First run cost**: provisioning + Claude session ≈ $0.10–$0.30 per ticket
  on Sonnet 4.6 for trivial fixes. Larger refactors run higher. The
  AI-spend footer makes this visible per PR; the sticky issue comment rolls
  up across iterations.
- **Org quota**: a fresh scratch org per run (and per PR-feedback iteration)
  hits your DevHub's daily/concurrent scratch-org limits. For low-volume
  repos this is fine. For higher volume, consider persisting an org per PR
  (an open follow-up).
- **The "stop and comment" path**: the SKILL has explicit stop conditions
  (schema changes, Flows, Permission Sets, missing repro, etc.). When
  Claude declines, she comments on the issue or PR with the reason instead
  of forcing a bad fix.

## Adapting for non-Salesforce projects

The pipeline is Salesforce-flavoured but the structure is generic:

- Swap `create-scratch-org.sh` for whatever provisions an isolated
  environment in your stack (a database, a preview deployment, a fresh
  branch in a partner system).
- Drop the SF CLI install + DevHub auth steps if you don't need them.
- Update the SKILL's deploy/test commands to match your toolchain.
- Keep the App-token, branch-naming, label, and AI-cost reporting machinery
  unchanged — those are not Salesforce-specific.

## Open follow-ups

Tracked as separate issues in this repo:

- Persistent scratch org per PR (avoid 5-min re-provisioning on every
  feedback iteration).
- More ticket shapes end-to-end (bug fixes, small feature tweaks).
- Verify-step parity for the PR-feedback workflow.
