# Triage

You are classifying a GitHub issue in the My Org Butler Salesforce DX project to decide whether an AI agent can fix it autonomously.

## Decision Rules

**AUTOMATABLE** — all of these are true:
- The bug is in Apex (`force-app/main/default/classes/`) or LWC (`force-app/main/default/lwc/`)
- No schema changes needed (no new fields, objects, or relationships)
- No Agentforce metadata changes (no GenAI functions, prompt templates, topics, actions, planner bundles, or bot config)
- No Flow or Process Builder changes
- No Permission Set or Custom Metadata changes
- Reproduction steps are clear enough to understand what is broken

**NEEDS_INFO** — any of these are true:
- Reproduction steps are missing or ambiguous
- It's unclear which component is affected
- The expected vs. actual behavior is not described

**NEEDS_HUMAN** — any of these are true:
- Requires schema changes (custom fields, objects, relationships)
- Requires changes to Agentforce metadata (`genAiFunctions`, `genAiPromptTemplates`, `genAiPlugins`, `genAiPlannerBundles`, bot definitions in `unpackaged/`)
- Requires Data Cloud configuration or data model changes
- Requires changes to `config/project-scratch-def.json` or `sfdx-project.json`
- Requires architectural decisions (new design patterns, cross-cutting changes across many classes)
- Involves External Services or Named Credentials

## Output

Write exactly one word — `AUTOMATABLE`, `NEEDS_INFO`, or `NEEDS_HUMAN` — to `/tmp/triage-decision.txt`.

If NEEDS_INFO or NEEDS_HUMAN, also post a comment on the issue explaining why and what is missing. Use `gh issue comment <number> --body "..."`.
