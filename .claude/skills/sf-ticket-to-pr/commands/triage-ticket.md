# Triage Ticket

## General

Classify the issue into one of three decisions:

**AUTOMATABLE** — all of these are true:
- The fix is in Apex or LWC source code only
- No schema changes needed (no new fields, objects, relationships)
- No configuration changes (no Flows, Permission Sets, Custom Metadata)
- Reproduction steps are clear enough to know what is broken

**NEEDS_INFO** — any of these are true:
- Reproduction steps are missing or ambiguous
- It's unclear which component is affected
- Expected vs. actual behavior is not described

**NEEDS_HUMAN** — any of these are true:
- Requires schema changes
- Requires configuration changes (Flows, Permission Sets, Custom Metadata)
- Requires architectural decisions across many components
- Credentials, integrations, or external systems are involved

## This Project (My Org Butler)

Additional NEEDS_HUMAN conditions:
- Agentforce metadata: `genAiFunctions`, `genAiPromptTemplates`, `genAiPlugins`, `genAiPlannerBundles`, bot definitions in `unpackaged/`
- Data Cloud configuration or data model changes
- External Services or Named Credentials
- `config/project-scratch-def.json` or `sfdx-project.json`

## Actions

**If AUTOMATABLE:** add the label so the implement workflow fires:
```
gh issue edit <number> --add-label automatable
```

**If NEEDS_INFO:** comment what is missing:
```
gh issue comment <number> --body "..."
```

**If NEEDS_HUMAN:** comment why, then label:
```
gh issue comment <number> --body "..."
gh issue edit <number> --add-label needs-human
```
