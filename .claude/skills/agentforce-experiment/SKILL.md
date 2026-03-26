---
name: agentforce-experiment
description: Optimize Agentforce prompt templates by testing model and prompt variants — conversational experiment design, no config files needed
argument-hint: "template name"
---

# Agentforce Prompt Experiment

You help users optimize Salesforce Agentforce prompt templates by systematically testing different models and prompt rewrites. You drive the entire process through conversation — no experiment spec files needed.

This skill builds on `agentforce-eval` for running tests via Promptfoo. You own the experiment workflow: proposing variants, creating template files, running comparisons, and reporting results.

## How it works

1. User names a template and what to optimize (e.g. "optimize ConsolidateMemory for latency")
2. You read the template, propose a matrix of variants
3. User confirms or adjusts
4. You create variant templates, deploy, test, report
5. User picks a winner — you apply it

No intermediate config. The conversation is the experiment design.

## Folder structure

All experiment artifacts live in `experiments/` at the project root:

```
experiments/
  {TemplateName}/
    experiment.yaml          # housekeeping manifest (what's here, status)
    run.yaml                 # promptfoo config to test all variants
    results.json             # promptfoo output
  main/default/genAiPromptTemplates/
    {Template}_{Variant}.genAiPromptTemplate-meta.xml
    ...
```

The `experiments/` folder is a Salesforce source directory listed in `sfdx-project.json`. Variant templates go in the standard metadata path so they can be deployed with:

```bash
sf project deploy start --source-dir experiments --concise
```

The `{TemplateName}/` subfolder holds experiment tracking — the deploy command ignores it.

## Step 0: Analyze and propose (REQUIRED)

Read the template XML from `force-app/main/default/genAiPromptTemplates/` and present:

```
## Experiment: {TemplateName}

**Current template:**
- Model: {current model}
- Content: {brief analysis — e.g. "5 rules, 2 examples, ~180 tokens"}
- Inputs: {list of {!$Input:...} vars}

**Proposed models:**
- {model 1} — {why}
- {model 2} — {why}

**Proposed content variants:**
1. **Shorter** — {what gets removed/changed, with rationale}
2. **Minimal** — {what gets removed/changed, with rationale}

**Matrix:** {N models} × {M content variants} = {total} variants

Proceed?
```

Wait for confirmation before continuing.

### Available models

Fetch the current list from: https://developer.salesforce.com/docs/einstein/genai/guide/supported-models.html

## Step 1: Create variant templates

For each permutation, create a new XML in `experiments/main/default/genAiPromptTemplates/`:

- Copy the original template XML
- `<developerName>`: `{Template}_{ModelShort}_{ContentVariant}` (e.g. `ConsolidateMemory_GPT41Mini_Shorter`)
- `<masterLabel>`: human-readable (e.g. `Consolidate Memory — GPT41Mini + shorter prompt`)
- `<description>`: what was changed
- Set `<primaryModel>` and/or `<content>` for this variant
- Set `<status>Published</status>`
- Remove `<activeVersionIdentifier>` and `<versionIdentifier>` tags entirely — empty tags cause deploy failures

### Content variant generation

When rewriting prompt content:

1. Read the current `<content>` from the template XML
2. Rewrite following the agreed instruction (e.g. "shorter, remove examples")
3. Preserve all `{!$Input:...}`, `{!$RecordSnapshot:...}`, and `{!$EinsteinSearch:...}` placeholders exactly
4. Use XML escaping (`&apos;`, `&quot;`, `&lt;`, `&gt;`) in the generated content

## Step 2: Deploy variants

```bash
sf agent deactivate --api-name MyOrgButler
sf project deploy start --source-dir experiments --concise
sf agent activate --api-name MyOrgButler
```

## Step 3: Create run.yaml and test

Generate a promptfoo YAML in the experiment folder. This uses the `sf-generations-api.mjs` provider from `agentforce-eval`:

```yaml
# experiments/{Template}/run.yaml
providers:
  - id: "file://../../.claude/skills/agentforce-eval/providers/sf-generations-api.mjs"
    label: "Einstein Generations API"

prompts:
  - "{{promptTemplateName}}"

defaultTest:
  options:
    provider: "openai:gpt-4o"
  assert:
    - type: javascript
      value: "output.success === true"
    - type: llm-rubric
      value: "{assertion from conversation}"

tests:
  - description: "Baseline: {original model} + original"
    vars:
      promptTemplateName: {OriginalTemplate}
      # ... template input vars
  - description: "{Model} + {content variant}"
    vars:
      promptTemplateName: {VariantName}
      # ... template input vars
```

Run it:

```bash
cd experiments/{Template} && npx promptfoo@latest eval -c run.yaml --env-file ../../agentforce-eval/.env --json -o results.json
```

## Step 4: Update experiment manifest

Each experiment folder has an `experiment.yaml` — a housekeeping manifest, not an execution spec:

```yaml
template: ConsolidateMemory
optimizing: latencyMs
status: completed          # proposed | running | completed
created: 2026-03-26

variants:
  - name: ConsolidateMemory_GPT41Mini
    model: sfdc_ai__DefaultGPT41Mini
    content: original
  - name: ConsolidateMemory_GPT41Mini_Shorter
    model: sfdc_ai__DefaultGPT41Mini
    content: shorter — removed examples section

winner: ConsolidateMemory_Gemini25Flash_Shorter
applied: false
```

Update `status` and `winner` as the experiment progresses.

## Step 5: Present results

Sort by the optimization target:

```
## Experiment Report: ConsolidateMemory

Optimizing for: latencyMs (lower is better)
Baseline: GPT4OmniMini + original content | 1200ms

| #  | Model            | Content              | Pass | latencyMs |
|----|------------------|----------------------|------|-----------|
| 1  | Gemini 2.5 Flash | shorter, no examples | 1/1  | 400       |
| 2  | Gemini 2.5 Flash | original             | 1/1  | 500       |
| 3  | GPT41Mini        | shorter, no examples | 1/1  | 600       |
| 4  | GPT41Mini        | original             | 1/1  | 800       |

Winner: #1 Gemini 2.5 Flash + shorter prompt — 67% faster than baseline, all tests pass.
```

Then list what's in the org:

```
Experiment variants in your org:
- ConsolidateMemory_GPT41Mini (GPT 4.1 Mini + original content)
- ConsolidateMemory_Gemini25Flash_Shorter (Gemini 2.5 Flash + shorter prompt)
- ...

You can test these manually in Prompt Builder. When done, say "clean up".
To apply the winner, say "apply #1".
```

## Step 6: Apply winner (on user request)

Copy the winning variant's `<primaryModel>` and `<content>` into the original template XML in `force-app/` and deploy.
Update `applied: true` in the manifest.

## Step 7: Cleanup (on user request)

Delete variant files and the metadata structure:

```bash
rm -rf experiments/main/default/genAiPromptTemplates/{Template}_*
```

Then destructive deploy or tell the user to delete manually in Setup → Prompt Templates.

## Rules

- Never modify the original template in `force-app/` during experiments — only when applying a winner
- Never auto-delete variant templates — the user may want to test them manually first
- Experiment folders are committed to git as history
- The `experiment.yaml` manifest is descriptive — it tracks what exists, it doesn't drive execution
