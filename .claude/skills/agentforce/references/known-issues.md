# Agent Script — Known Issues & Quirks

> Track bugs, limitations, and quirks discovered during Agent Script development.
> Agent Script is still in beta. Update this file when you discover issues or when Salesforce fixes them.

---

## OPEN: Agent test files block deployment of entire force-app

**Discovered:** 2026-02-11
**Status:** OPEN
**Symptom:** Running `sf project deploy start --source-dir force-app` hangs at "Waiting for the org to respond" for 2+ minutes, then gets canceled. The deployment includes agent test files (AiEvaluationDefinitions) which cannot be deployed while the agent is active.

**Root cause:** Agent tests in `regressions/aiEvaluationDefinitions/` must not be in `force-app/`. They require special deployment workflow: deactivate agent → deploy tests → reactivate agent.

**Workaround:**
- Move agent tests out of `force-app/` to a separate directory like `regressions/`
- OR: Use separate deployments: `sf project deploy start --source-dir force-app/main/default` (excludes tests)
- Follow CLAUDE.md workflow for agent test deployment

**Related:** See CLAUDE.md "Deploying Agent Tests" section for the correct workflow.

---

<!--
## Template for new issues

## OPEN/FIXED: <short description>

**Discovered:** YYYY-MM-DD
**Status:** OPEN | FIXED (Salesforce version) | WORKAROUND
**Symptom:** What you observe
**Root cause:** Why it happens (if known)
**Workaround:** How to avoid or work around it
**Related:** Links to docs, similar issues, etc.

---
-->
