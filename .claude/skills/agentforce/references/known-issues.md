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

## OPEN: sf agent publish fails with "invocable action does not exist" despite classes deployed

**Discovered:** 2026-02-11
**Status:** OPEN — needs resolution
**Project:** my-org-butler (namespace: aquiva_os)

**Symptom:**
After successfully deploying all Apex classes with @InvocableMethod annotations to scratch org, running `sf agent publish authoring-bundle --api-name MyOrgButler` fails with:
```
Error (1): Failed to publish agent with the following errors:
Validation failed for action(s) 'load_custom_instructions' due to invalid attribute value for 'target'.
Invocable action 'LoadCustomInstructions' does not exist.
To fix, please ensure the 'target' value points to a valid invocable action.
```

**Context:**
- Project has namespace `aquiva_os` in sfdx-project.json
- Scratch org created from this project inherits the namespace
- Apex classes confirmed deployed to org via SOQL query (LoadCustomInstructions, QueryRecordsWithSoql, ExploreOrgSchema, StoreCustomInstruction all present)
- All classes have proper `@InvocableMethod` annotations (label and description)
- Agent file uses targets like `target: "apex://LoadCustomInstructions"`
- Syntax matches working examples from agent-script-recipes repo (which uses no namespace)
- Old system (genAiFunctions) used `<invocationTarget>LoadCustomInstructions</invocationTarget>` without namespace and worked

**What we tried:**
- Confirmed classes exist in org with SOQL queries
- Confirmed @InvocableMethod annotations present and correct
- Checked agent-script-recipes for working examples — they use `apex://ClassName` format
- Confirmed VF page (sessionId) deployed successfully (was not the blocker)
- Full force-app deployment succeeded (53/53 components)

**Unresolved questions:**
1. Does Agent Script require namespace prefix in apex:// targets when project has namespace? (e.g., `apex://aquiva_os__LoadCustomInstructions`)
2. Is this a beta bug where namespace resolution fails in sf agent publish?
3. Is there a required annotation parameter we're missing to make invocable methods discoverable?
4. Does the scratch org namespace need special handling vs. recipes repo (which likely has no namespace)?

**Need to investigate:**
- Search GitHub for Agent Script projects WITH namespaces that successfully use apex:// targets
- Check if namespace prefix syntax differs (underscore vs. dot: `aquiva_os__` vs `aquiva_os.`)
- Verify if there's a way to query registered invocable actions in the org
- Check Salesforce DX setup for namespace-related configurations

**For Slack/issue reporting:**
Environment: Scratch org with namespace aquiva_os, Agent Script beta, SF CLI latest
Deployment: All Apex classes successfully deployed and visible via SOQL
Error: sf agent publish cannot find invocable actions that use apex:// targets
Working: Old genAiFunction system found same classes with same invocation targets
Question: How should apex:// targets reference invocable methods in namespaced scratch orgs?

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
