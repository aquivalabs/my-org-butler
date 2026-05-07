# SF Ticket → PR

A GitHub Actions pipeline that turns issues into tested pull requests, and turns reviewer comments on those PRs into follow-up commits. No human edits the code.

## TL;DR

1. Open an issue.
2. A PR appears in a few minutes — branch made, code deployed to a fresh scratch org, Apex tests green, PMD clean on touched lines.
3. Comment on the PR in plain English.
4. A new commit lands.
5. Approve, merge.

## Highlights

| | |
| --- | --- |
| **Knows when to stop** | Schema changes, Flows, Permission Sets, vague repros → Claude posts a comment instead of forcing a bad fix. Stop conditions live in [SKILL.md](SKILL.md). |
| **Bot identity** | Commits and PRs are attributed to `claude-bot[bot]` via a GitHub App, not a personal token. The human reviewer stays eligible to approve, and AI vs. human authorship is visible at a glance. |
| **Setup work outside the agentic loop** | Branching, scratch-org provisioning, deploy and baseline tests run as plain shell steps before Claude is invoked. The expensive turn-taking loop only sees a ready environment. |
| **Reuses the developer's onboarding script** | The runner runs the same [create-scratch-org.sh](../../../scripts/create-scratch-org.sh) a developer runs on their laptop — it just toggles `HEADLESS=true` to skip the steps that need a human (Data Library upload, manual permset assignments). One source of truth for "what is a working org". |
| **Cost per run** | Each run appends a `🤖 sonnet-4-6 · $0.12 · 18k tokens` footer to the PR or comment. The originating issue carries a sticky rollup across all iterations. |
| **Two flows, one prompt** | Issue→PR and PR-comment→commit both invoke [SKILL.md](SKILL.md). |

## How it works

```mermaid
sequenceDiagram
    autonumber
    actor Dev
    participant GH as GitHub
    participant WF as Workflow runner
    participant CC as Claude Code
    participant Org as Scratch Org

    Dev->>GH: open issue
    GH-->>WF: trigger sf-ticket-to-pr.yml
    WF->>WF: mint App token, checkout, branch fix/issue-N
    WF->>Org: create-scratch-org.sh (deploy + baseline tests)
    WF->>CC: prompt = SKILL.md + issue body
    CC->>Org: deploy changed file, run Apex tests, run PMD
    CC->>GH: gh pr create --label ai-generated
    WF->>GH: append cost footer to PR

    Dev->>GH: review comment on the PR
    GH-->>WF: trigger sf-pr-feedback.yml
    WF->>Org: fresh scratch org
    WF->>CC: prompt = SKILL.md + comment body
    CC->>Org: deploy + test as above
    CC->>GH: git push to existing branch
    WF->>GH: append cost footer to comment
```

The runner does the deterministic work (CLI install, auth, branching, scratch-org provisioning). Claude is only asked to write code.

## File map

| File | Role |
| --- | --- |
| [.github/workflows/sf-ticket-to-pr.yml](../../../.github/workflows/sf-ticket-to-pr.yml) | Issue → PR. Fires on `issues: opened`. |
| [.github/workflows/sf-pr-feedback.yml](../../../.github/workflows/sf-pr-feedback.yml) | PR comment → commit. Fires on `issue_comment` / `pull_request_review_comment` if the PR has the `ai-generated` label. |
| [SKILL.md](SKILL.md) | The prompt. Decide → Code → Verify → Ship. Stop conditions and anti-patterns at the bottom. |
| [.claude/settings.json](../../settings.json) | Tool allow-list for Claude (bash commands, `Read`/`Edit`/`Write`). |
| [scripts/create-scratch-org.sh](../../../scripts/create-scratch-org.sh) | The same script developers run locally; `HEADLESS=true` skips the human-only steps. |
| [scripts/report-ai-cost.sh](../../../scripts/report-ai-cost.sh) | Reads cost + tokens from the action's `execution_file` output, appends a footer to the PR/comment, updates the sticky rollup on the issue. |

## Adopt this in your repo

Prereqs: GitHub org admin, Salesforce DevHub, Anthropic API key.

### 1. Copy the files

```text
.github/workflows/sf-ticket-to-pr.yml
.github/workflows/sf-pr-feedback.yml
.claude/skills/sf-ticket-to-pr/      (whole folder)
.claude/settings.json
scripts/create-scratch-org.sh
scripts/report-ai-cost.sh
```

Non-Salesforce repo? Keep everything except [scripts/create-scratch-org.sh](../../../scripts/create-scratch-org.sh) and the SF CLI steps in the workflows. Replace the deploy/test commands in [SKILL.md](SKILL.md) with your toolchain's equivalents.

Provisioning contract: `HEADLESS=true ./scripts/create-scratch-org.sh` must exit 0 when the environment is ready. No prompts, no `sf org open`, no human-gated waits.

### 2. Create the Claude Bot GitHub App (org-wide, once)

The default `GITHUB_TOKEN` cannot push branches that contain workflow files — GitHub blocks it regardless of the `permissions:` block. A GitHub App with the `workflows` permission is the canonical fix and also keeps authorship attributed to a bot user.

In **Settings → Developer settings → GitHub Apps → New GitHub App**:

- Disable webhooks.
- Repository permissions — **Contents**, **Issues**, **Pull requests**, **Workflows**: read & write. **Metadata**: read.
- Restrict installation to your own account.
- Generate a private key (PEM); note the numeric App ID.
- **Install** the App on the target repo.

### 3. Set repo secrets

In **Settings → Secrets and variables → Actions**:

| Secret | Value |
| --- | --- |
| `CLAUDE_BOT_APP_ID` | Numeric App ID from step 2. |
| `CLAUDE_BOT_PRIVATE_KEY` | Full PEM, including `BEGIN`/`END` lines. |
| `SFDX_AUTH_URL` | `sf org display --verbose --target-org <devhub> --json \| jq -r '.result.sfdxAuthUrl'` |
| `ANTHROPIC_API_KEY` | Anthropic API key. Or set `CLAUDE_CODE_OAUTH_TOKEN` instead to bill an Anthropic Max subscription. |

### 4. Create the label

```bash
gh label create ai-generated \
  --description "PR opened by the SF ticket-to-PR pipeline" \
  --color FBCA04
```

The PR-feedback workflow filters on this label; the issue workflow applies it via [SKILL.md](SKILL.md).

### 5. Smoke test

Open a small, well-scoped issue. The workflow fires, a PR appears, the cost footer shows up on the PR body. Comment on the PR asking for a tweak — a new commit lands on the same branch.

## Under the hood

### Cost reporting

[anthropics/claude-code-action](https://github.com/anthropics/claude-code-action) emits an `execution_file` output — a JSON array of the SDK messages from the run. [scripts/report-ai-cost.sh](../../../scripts/report-ai-cost.sh) reads the final `result` message with `jq`, pulls `total_cost_usd` and the per-token-type usage, and:

- Appends a one-line footer to the PR body (issue flow) or to the triggering comment (feedback flow).
- Maintains a sticky comment on the originating issue (resolved from `Closes #N` in the PR body). Each run is stored as an HTML marker like `<!-- run wf=… cost=… tokens=… -->`, so totals can be re-derived from the comment without parsing prose.

No `ccusage`, no `npm`, no JSONL diffing — the action already has the numbers.

### Bot authorship

The git author email is derived at runtime from the App's installation slug as `${USER_ID}+${APP_SLUG}[bot]@users.noreply.github.com` — the only form GitHub accepts on the `noreply` domain for `[bot]` users. See the **Create branch for the fix** step in [.github/workflows/sf-ticket-to-pr.yml](../../../.github/workflows/sf-ticket-to-pr.yml).

### Scratch org per iteration

Every PR-feedback comment provisions a fresh scratch org today — ~5 min of overhead, but the runner stays stateless. A parallel stream is in progress to persist one scratch org across the lifetime of a PR, so feedback iterations skip the re-provisioning entirely.

### Stop conditions

Defined in [SKILL.md](SKILL.md). Claude posts a comment and exits when the issue or feedback requires:

- Schema changes (objects, fields, relationships)
- Flows, Permission Sets, Custom Metadata, or anything under `unpackaged/`
- Data Cloud, External Services, Named Credentials, `config/`, or `sfdx-project.json`
- A vague repro or feedback that contradicts the original issue
- A cross-component architectural decision

## Open follow-ups

- Verify-step parity in the PR-feedback workflow.
- Broader ticket shapes end-to-end (small features, not only bug fixes).
