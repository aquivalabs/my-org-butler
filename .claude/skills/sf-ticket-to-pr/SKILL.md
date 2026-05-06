---
name: sf-ticket-to-pr
description: AI-driven pipeline that turns GitHub issues into reviewed, tested Apex/LWC pull requests
argument-hint: "triage-ticket|implement-fix|review-pr"
---

# SF Ticket to PR

## Commands

- **`triage-ticket`** — Read `commands/triage-ticket.md`. Classify a GitHub issue as AUTOMATABLE, NEEDS_INFO, or NEEDS_HUMAN.
- **`implement-fix`** — Read `commands/implement-fix.md`. Write an Apex/LWC fix, push branch (workflow handles deploy + PR).
- **`review-pr`** — Read `commands/review-pr.md`. Review a human-authored PR and post a comment.

If no argument is given, ask what the user wants to do.
