---
name: agentforce-deploy
description: "Use when creating, editing, or deploying Salesforce Agentforce metadata — genAiFunctions, genAiPromptTemplates, genAiPlugins, genAiPlannerBundles, or bots — in any sfdx project with these directories under one of the `packageDirectories` declared in `sfdx-project.json`. Encodes the manual fixups Salesforce CLI does not handle — schema.json scaffolding, prompt-template versionIdentifier bumps, deployment-detection nudge for schema-only edits, bot topic refresh, and bot deactivation when deploys are blocked by an active agent."
---

# Agentforce Deploy

Salesforce CLI has gaps when iterating on Agentforce metadata. Apply the relevant rule(s) below, then deploy with `sf project deploy start` (the user's global rule). Use `sf project deploy preview` first if unsure what's in the payload — especially for rule 4. Path examples use `force-app/main/default/...`; substitute the correct `packageDirectories` entry from `sfdx-project.json`.

## 1. Creating a genAiFunction

A genAiFunction is a directory of three files. **All three must exist** or the deploy looks successful but the function is unusable.

```
<packageDir>/main/default/genAiFunctions/<Name>/
├── <Name>.genAiFunction-meta.xml
├── input/schema.json
└── output/schema.json
```

Baseline `schema.json` shape (drop `required` for the output schema):

```json
{
  "lightning:type": "lightning__objectType",
  "unevaluatedProperties": false,
  "required": ["exampleField"],
  "properties": {
    "exampleField": {
      "title": "Example Field",
      "description": "Human-readable description shown to the planner.",
      "lightning:type": "lightning__textType",
      "lightning:isPII": false,
      "copilotAction:isDisplayable": true,
      "copilotAction:isUserInput": true
    }
  }
}
```

If a sibling function exists, prefer copying its schema for project-specific conventions. If the user provides only an Apex action, infer properties from the `@InvocableVariable` fields.

## 2. Creating a genAiPromptTemplate

`<activeVersionIdentifier>` is required and must match `<versionIdentifier>` inside the active `<templateVersions>` block — without it the template deploys but is not addressable.

```xml
<GenAiPromptTemplate ...>
    <activeVersionIdentifier>SomeOpaqueId_1</activeVersionIdentifier>
    ...
    <templateVersions>
        <versionIdentifier>SomeOpaqueId_1</versionIdentifier>
        ...
    </templateVersions>
</GenAiPromptTemplate>
```

For new templates, use a placeholder like `<DeveloperName>_v1`; the org overwrites it on first activation in Prompt Builder.

## 3. Editing an existing genAiPromptTemplate

When changing `<content>`, `<inputs>`, or anything inside `<templateVersions>`, bump the trailing `_N` on both `<activeVersionIdentifier>` and `<versionIdentifier>` — they must stay identical.

Example: `xmzQO5r6hnZqbok3Q3WIil5GwtcQOnJbozjqBDMdyp8=_3` → `..._4`

The new version is live as soon as the deploy succeeds — no UI re-activation needed.

## 4. Editing only schema.json on a genAiFunction

Salesforce CLI does **not** detect changes to `input/schema.json` or `output/schema.json` alone — the deploy reports success while shipping nothing. Confirm with `sf project deploy preview` if in doubt.

To force the function into the payload, toggle a single trailing space inside any non-`<description>` element of the sibling `.genAiFunction-meta.xml` (e.g. `<masterLabel>Foo</masterLabel>` → `<masterLabel>Foo </masterLabel>`). Avoid editing `<description>` — the planning LLM reads it at runtime.

## 5. Editing a genAiPlugin (topic) or its functions

Bots cache their planner bundle, so plugin/function edits don't propagate from a deploy alone. To refresh:

1. Open `<packageDir>/main/default/genAiPlannerBundles/<Bundle>/<Bundle>.genAiPlannerBundle`.
2. Remove the `<genAiPlugins><genAiPluginName>X</genAiPluginName></genAiPlugins>` block for the changed plugin.
3. Deploy.
4. Re-add the block.
5. Deploy again.

If rule 6's deactivate/reactivate cycle is already needed, skip the bundle dance — the activation step rebinds the planner.

## 6. Deploy fails because the agent is active

Symptom: `sf project deploy start` fails on genAi* metadata referencing the bot/agent being active. **Do not** preemptively deactivate.

```bash
sf agent deactivate -o <target-org> -n <AgentApiName>
sf project deploy start ...
sf agent activate -o <target-org> -n <AgentApiName>
```

Resolve `<AgentApiName>` from `<packageDir>/main/default/bots/` (or `unpackaged/bots/`). If multiple bots exist, the deploy error names the failing one. Always pass `-n` in non-interactive contexts. Default org: `sf config get target-org`. Always reactivate after deploy succeeds.

## Deployment checklist

- [ ] New genAiFunction → both `input/schema.json` and `output/schema.json` exist (rule 1)
- [ ] New genAiPromptTemplate → `<activeVersionIdentifier>` matches inner `<versionIdentifier>` (rule 2)
- [ ] Edited genAiPromptTemplate → `_N` suffix bumped on both identifiers (rule 3)
- [ ] schema.json edited → trailing-whitespace nudge on sibling `.genAiFunction-meta.xml` (non-description) (rule 4)
- [ ] genAiPlugin/function edited → topic-refresh dance, or combine with rule 6 (rule 5)
- [ ] Deploy fails on active agent → deactivate/deploy/reactivate with resolved API name (rule 6)
