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
- Run agent-test deployment as a separate step from core metadata deployment.

---

## OPEN: sf agent publish fails with "Internal Error, try again later" after successful validate

**Discovered:** 2026-02-13
**Status:** OPEN — publish-stage failure
**Project:** my-org-butler (namespace: aquiva_os)

**Symptom:**
`sf agent validate authoring-bundle --api-name MyOrgButler` succeeds, but `sf agent publish authoring-bundle --api-name MyOrgButler` fails with:
```
Failed to publish agent with the following errors:
Internal Error, try again later
```

**Confirmed context:**
- Apex classes deploy successfully.
- Namespaced `apex://` targets are used in the `.agent` file (for example `apex://aquiva_os__LoadCustomInstructions`).
- Prompt action inputs use `Input:*` names.
- Prompt-template SObject inputs are already configured in required publish format (`object` + `complex_data_type_name: lightning__recordInfoType`).
- Failure occurs in publish stage (`POST /einstein/ai-agent/v1.1/authoring/agents`), not in compile/validate stage.

**Likely causes to investigate:**
- Backend Agent Script publish bug.
- Residual action contract mismatch that passes compile but fails publish (similar to recipes issue #8).

**Need to investigate:**
- Isolate publish by temporarily removing prompt actions and republishing.
- Compare action input/output contracts one-by-one against invocable and prompt template metadata.
- Raise Salesforce support case with org id, timestamp, and publish endpoint details from CLI logs.

**Related:**
- https://github.com/trailheadapps/agent-script-recipes/issues/8

---

## OPEN: `validate` accepts prompt-template input type `id`, but `publish` requires `object` + `complex_data_type_name`

**Discovered:** 2026-02-13
**Status:** OPEN — inconsistent validation behavior
**Project:** my-org-butler (namespace: aquiva_os)

**Why this matters:**
For prompt-template actions with SObject inputs, `sf agent validate` can pass even when input types are invalid for publish. This makes pre-publish checks unreliable.

**Repro steps (A/B):**
1. In `MyOrgButler.agent`, change prompt input:
   - `"Input:opportunity": id` (instead of `object` + `complex_data_type_name`)
2. Run validate:
   - `sf agent validate authoring-bundle --api-name MyOrgButler --target-org my-org-butler_DEV`
   - Result: success (unexpected)
3. Run publish:
   - `sf agent publish authoring-bundle --api-name MyOrgButler --target-org my-org-butler_DEV`
   - Result: fails with
```
Validation failed for action 'answer_with_related_files' due to invalid data type for the input parameter 'Input:opportunity'. To fix, update the data type to 'object' type and 'complex_data_type_name' to 'lightning__recordInfoType' for the input parameter 'Input:opportunity'.
```
4. Restore prompt inputs to:
   - type `object`
   - `complex_data_type_name: "lightning__recordInfoType"`
5. Re-run validate:
   - Result: success
6. Re-run publish:
   - Datatype error disappears; current blocker remains the separate internal publish error.

**Expected:**
- `validate` should reject `id` in step 2 with the same contract error seen in publish.

**Actual:**
- `validate` passes.
- `publish` rejects input contract.

**Workaround:**
- For prompt-template inputs backed by `SOBJECT://...` in prompt template metadata, use:
  - `object`
  - `complex_data_type_name: "lightning__recordInfoType"`

---

## OPEN: `validate` accepts non-namespaced Apex target, but `publish` rejects it in namespaced scratch org

**Discovered:** 2026-02-13
**Status:** OPEN — inconsistent validation behavior
**Project:** my-org-butler (namespace: aquiva_os)

**Why this matters:**
In a namespaced org, `sf agent validate` reports success for an action target that `sf agent publish` later rejects as invalid. This makes CI checks unreliable because validate can pass while publish is guaranteed to fail.

**Repro steps (A/B):**
1. Use namespaced target in Agent Script:
   - `target: "apex://aquiva_os__LoadCustomInstructions"`
2. Run:
   - `sf agent validate authoring-bundle --api-name MyOrgButler --target-org my-org-butler_DEV`
   - Result: success
3. Change same target to non-namespaced:
   - `target: "apex://LoadCustomInstructions"`
4. Run validate again:
   - `sf agent validate authoring-bundle --api-name MyOrgButler --target-org my-org-butler_DEV`
   - Result: success (unexpected)
5. Run publish:
   - `sf agent publish authoring-bundle --api-name MyOrgButler --target-org my-org-butler_DEV`
   - Result: fails with
```
Validation failed for action(s) 'load_custom_instructions' due to invalid attribute value for 'target'.
Invocable action 'LoadCustomInstructions' does not exist.
```

**Expected:**
- Either `validate` should fail in step 4 with the same namespace/action resolution error.
- Or `publish` should resolve non-namespaced action names consistently in namespaced orgs.

**Actual:**
- `validate` passes.
- `publish` fails due to missing invocable action.

**Confirmed environment:**
- Scratch org alias: `my-org-butler_DEV`
- Scratch org id: `00DRt00000MiNh5MAF`
- Scratch username: `test-bgvj5fomcbda@example.com`
- Salesforce CLI: `2.122.6`
- Agent plugin: `1.29.0`

**Workaround:**
- Always use namespaced `apex://` targets in `.agent` files for namespaced orgs (for example `apex://aquiva_os__ClassName`).

---

## WORKAROUND: Source tracking can be poisoned by deploys from temporary paths

**Discovered:** 2026-02-13
**Status:** WORKAROUND

**Symptom:**
Deploy and reset commands fail with:
```
UnsafeFilepathError: The filepath "../../../../../tmp/.../Wsdl.cls" contains unsafe character sequences
```

**Root cause:**
Local source tracking index for the target org contains stale `../../../../../tmp/...` paths from a deploy run that used a temporary folder as source.

**Workaround:**
- Deploy only from repo paths (`force-app/...`), not temporary copied directories.
- If already poisoned:
  - Delete `.sf/orgs/<target-org-id>/localSourceTracking/`
  - Run `sf project reset tracking --target-org <alias> --no-prompt`
  - Retry deployment

---

## OPEN: Agent packaging workflow unclear — no template mechanism like old Bot Templates

**Discovered:** 2026-02-11
**Status:** OPEN — needs documentation/guidance
**Project:** my-org-butler (managed package)

**Context:**
In the old Agentforce system (pre-Agent Script), packaging worked via Bot Templates:
- You packaged the Bot Template (not the bot itself)
- Subscriber admins would unpackage the template and create a new agent instance from it
- This allowed customization per subscriber org

**Current state with Agent Script:**
- No Bot Template concept exists anymore
- Unclear how to package Agent Script agents for distribution
- No documentation found on managed package distribution workflow for .agent files
- Unknown if subscribers can customize published agents

**Questions:**
1. How do you package Agent Script agents for AppExchange/managed packages?
2. Can subscriber orgs customize packaged agents?
3. Is there a new "template" mechanism or is everything locked?
4. Do .agent files deploy as-is to subscriber orgs with no customization option?

**Need to investigate:**
- Salesforce packaging docs for Agent Script
- Whether aiAuthoringBundles support managed package distribution
- Subscriber org experience with packaged agents

---

## OPEN: Legacy SF agent CLI commands deprecated or broken for Agent Script

**Discovered:** 2026-02-11
**Status:** OPEN — CLI transition incomplete

**Symptom:**
Most `sf agent` commands from the old Agentforce system appear not to work with Agent Script agents.

**Context:**
- Old commands were designed for bot/bot version architecture
- Agent Script uses aiAuthoringBundles, not bots
- Commands may be deprecated but no clear migration guide exists
- `sf agent publish authoring-bundle` is the new workflow, but other commands unclear

**Examples of unclear/broken commands:**
- Old bot management commands don't recognize Agent Script agents
- Test execution commands may need different syntax
- Activation/deactivation workflows differ

**Need to investigate:**
- Full list of `sf agent` commands and their Agent Script equivalents
- Official migration guide from bot commands to Agent Script commands
- Which commands are deprecated vs. updated for Agent Script

---

## OPEN: Agent tests cannot be deployed — old XML references bot/version, new tests not retrievable

**Discovered:** 2026-02-11
**Status:** OPEN — testing workflow broken

**Symptom:**
Cannot deploy existing agent test XML files. They reference bot and version fields that don't exist in Agent Script agents.

**Old test format (doesn't work):**
- XML files in `regressions/aiEvaluationDefinitions/`
- Reference bot API name and version
- Agent Script agents have no version concept

**New test format (in org, not deployable):**
- Can create new tests in org UI
- More versatile — supports data mocking
- **Cannot retrieve/pull these tests to local project**
- No metadata type or CLI command to fetch them

**Broken workflow:**
1. Old tests won't deploy (reference non-existent bot/version)
2. New tests can't be source-controlled (can't pull from org)
3. No clear migration path from old test format to new

**Questions:**
1. Is there a new metadata type for Agent Script tests?
2. How do you retrieve org-created tests to local project?
3. Is there a migration tool/process for old test XML?
4. How do you version-control Agent Script tests?

**Need to investigate:**
- Metadata API coverage for Agent Script tests
- `sf project retrieve` commands for test definitions
- Test definition format in Agent Script
- Official testing workflow documentation

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
