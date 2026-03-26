# /agentforce experiment — Optimize Prompt Templates

Optimize Agentforce prompt templates by testing model and prompt variants. The conversation is the experiment design — no config files needed.

## How it works

1. User names a template and what to optimize (e.g. "optimize ConsolidateMemory for latency")
2. You read the template and the learnings file, then propose a matrix of variants
3. User confirms or adjusts
4. You create variant templates, deploy, test, report
5. You store learnings from the results
6. User picks a winner — you apply it

## Learnings

Before proposing any experiment, read `learnings.md` in this skill folder. It contains accumulated knowledge about what works and what doesn't — seeded with general optimization ideas and updated after every experiment.

After presenting results, **always append new learnings** to `learnings.md`. What surprised you? What pattern held? What failed? This is how the skill gets smarter over time.

## Experiment folder

Variant templates and results are stored in an `experiments/` subfolder:

- If `unpackaged/` exists at the project root, store experiments in `unpackaged/experiments/`
- Otherwise, ask the user where to put them

The folder uses proper Salesforce metadata structure so it can be deployed directly:

```
unpackaged/experiments/
  {TemplateName}/
    experiment.yaml          # housekeeping manifest
    run.yaml                 # promptfoo config
    results.json             # promptfoo output
  main/default/genAiPromptTemplates/
    {Template}_{Variant}.genAiPromptTemplate-meta.xml
    ...
```

Deploy with: `sf project deploy start --source-dir unpackaged/experiments --concise`

The `{TemplateName}/` subfolder holds experiment tracking — the deploy command ignores non-metadata files.

## Step 0: Analyze and propose (REQUIRED)

Read the template XML from `force-app/main/default/genAiPromptTemplates/`. Read `learnings.md` from this skill folder. Then present:

```
## Experiment: {TemplateName}

**Current template:**
- Model: {current model}
- Content: {brief analysis — e.g. "5 rules, 2 examples, ~180 tokens"}
- Inputs: {list of {!$Input:...} vars}

**Learnings that apply:**
- {relevant insights from learnings.md}

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

When proposing models, consider what you know from `learnings.md` about model performance on similar tasks.

## Step 1: Create variant templates

For each permutation, create a new XML in the experiment folder's `main/default/genAiPromptTemplates/`:

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
2. Apply learnings from `learnings.md` — e.g. if past experiments show "removing examples rarely hurts quality", use that insight
3. Rewrite following the agreed instruction
4. Preserve all `{!$Input:...}`, `{!$RecordSnapshot:...}`, and `{!$EinsteinSearch:...}` placeholders exactly
5. Use XML escaping (`&apos;`, `&quot;`, `&lt;`, `&gt;`) in the generated content

## Step 2: Deploy variants

```bash
sf agent deactivate --api-name MyOrgButler
sf project deploy start --source-dir unpackaged/experiments --concise
sf agent activate --api-name MyOrgButler
```

## Step 3: Create run.yaml and test

Generate a promptfoo YAML in the experiment folder:

```yaml
# unpackaged/experiments/{Template}/run.yaml
providers:
  - id: "file://../../.claude/skills/agentforce/providers/sf-generations-api.mjs"
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
cd unpackaged/experiments/{Template} && npx promptfoo@latest eval -c run.yaml --env-file ../../../agentforce-eval/.env --json -o results.json
```

## Step 4: Update experiment manifest

Each experiment folder has an `experiment.yaml` — a housekeeping manifest:

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

Then list what's in the org and offer next steps:

```
Experiment variants in your org:
- ConsolidateMemory_GPT41Mini (GPT 4.1 Mini + original)
- ConsolidateMemory_Gemini25Flash_Shorter (Gemini 2.5 Flash + shorter)

You can test these manually in Prompt Builder. When done, say "clean up".
To apply the winner, say "apply #1".
```

## Step 6: Store learnings (REQUIRED — do not skip)

After presenting results, append insights to `learnings.md` in this skill folder. Format:

```markdown
### {TemplateName} — {date}

- {insight about what worked or didn't}
- {surprising result}
- {pattern confirmed or disproven}
```

**Only store meta-learnings about process and methodology** — how to deploy correctly, how to measure reliably, what tools/flags to use. Never store project-specific results like "Model X is faster than Model Y" — those belong in `results.json` and the experiment manifest, not in learnings. Learnings must be useful across any project, any template, any model.

## Step 7: Apply winner (on user request)

Copy the winning variant's `<primaryModel>` and `<content>` into the original template XML in `force-app/` and deploy. Update `applied: true` in the manifest.

## Step 8: Cleanup (on user request)

Delete variant files:

```bash
rm -rf unpackaged/experiments/main/default/genAiPromptTemplates/{Template}_*
```

Then destructive deploy or tell the user to delete manually in Setup → Prompt Templates.

## Rules

- Never modify the original template in `force-app/` during experiments — only when applying a winner
- Never auto-delete variant templates — the user may want to test them manually
- Experiment folders are committed to git as history
- Always read `learnings.md` before proposing and write to it after results
