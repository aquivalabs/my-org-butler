# Agent Script Migration — Plan & Status

Working doc for the migration of My Org Butler from classic Agentforce metadata
(GenAiPlannerBundle / genAiPlugin / genAiFunctions) to Agent Script (AiAuthoringBundle).
Branch: `migration-to-agent-script-v2`. Both worlds live side by side on this branch;
the classic metadata stays untouched as reference until the migration is complete.

## Goal

1. **Naive 1:1 port** of the classic agent to Agent Script — same topic, same 18 actions,
   same instructions. Proves feature parity. ✅ done
2. **Deterministic refactor** — replace prompt-engineering guardrails with Agent Script
   language constructs (the actual payoff, see mapping table below). ⏳ next
3. **Eval parity** — Testing Center + multi-turn suites run green against the script agent.
4. **Packaging** via forcedotcom/lwc-agentscript-viewer (AiAuthoringBundle is NOT
   2GP-packageable; Metadata Coverage v66: managed & unlocked both false).
5. **README** — "one agent, two implementations" showcase.

## Current State (2026-07-22)

- `force-app/main/default/aiAuthoringBundles/MyOrgButler/MyOrgButler.agent` — full naive
  port: 15 Apex actions (`apex://<Class>`), 1 prompt template
  (`generatePromptResponse://AnswerFromFile`), 2 standard actions
  (`standardInvocableAction://identifyRecordByName` + `getDataForGrounding`,
  source `EmployeeCopilot__*`). Published and ACTIVE in scratch org `my-org-butler_DEV`.
- Live smoke tests pass: LoadCustomInstructions (user context), SOQL prioritization
  (Acme Q1 Expansion Deal), ExploreOrgSchema (Memory__c fields), task creation, web search.
- Demo-story multi-turn (REST): 5/8 pass. Fails: turn 1 (memory content not surfaced —
  instruction tuning for Phase 2), turn 3 (file context not passed by ad-hoc runner —
  harness gap), turn 4 (Data Library chunk table empty — org data problem, re-upload
  policy.pdf in library UI).
- `scripts/create-scratch-org.sh` publishes + activates the agent from the Agent Script
  bundle; classic metadata deploys but is never activated.
- Hardcoded Data-Cloud entity names removed from `agent-eval/Regression...xml` (case 10)
  and `demo-story.yaml` (turn 1) — entity names are org-specific
  (`ADL_<random>_MyOrgButl_chunk__dlm`), the agent must discover them via ExploreDataCloud.

## Hard-won platform facts (do not re-learn these)

1. **Zero-input actions break the runtime.** An action declared without `inputs:` compiles
   and publishes fine but every session dies with `InvalidPlannerConfigException: Unable to
   load agent config`. Fix: declare a dummy optional input (`ignored: string`) — the Apex
   Input class has this field for the same reason (classic had the same issue).
   `validate` AND `publish` both pass on the broken config; only sessions fail.
   Candidate for a bug report against forcedotcom/cli.
2. **`sf agent publish` only finds bundles in the DEFAULT package directory.**
   `validate` searches all package dirs — publish doesn't. That's why `force-app` is now
   `"default": true` in sfdx-project.json.
3. **`sf agent preview --api-name` cannot start sessions for Employee agents** —
   `bypassUser: true` is hardcoded ([forcedotcom/cli#3608](https://github.com/forcedotcom/cli/issues/3608)).
   Workarounds: `--authoring-bundle` variant, or the invocable REST endpoint (below).
4. **Smoke-test channel that works:** POST
   `/services/data/v66.0/actions/custom/generateAiAgentResponse/MyOrgButler`
   with `{"inputs":[{"userMessage":"...", "sessionId":"<from previous response>"}]}`.
   Works for classic AND script agents (both compile to Bot + GenAiPlannerBundle).
5. **`versionTag` in bundle-meta.xml is dead metadata.** The publish API never receives it
   (verified in @salesforce/agents source). Builder version labels ("v0.1") are the
   Builder's own counter, bumped only via its "New Version" button. CalVer via versionTag
   does not work.
6. **Published versions are effectively undeletable.** Every publish creates a BotVersion
   locked by `AiAuthoringBundleDefVer` references (DEPENDENCY_EXISTS on delete; those
   entities aren't SOQL-accessible; authoring API has no DELETE). Only fix: delete the
   whole agent and republish once. Iterating on one org piles up versions — accepted cost.
7. **Version activation without the interactive picker:**
   `POST /services/data/v66.0/connect/bot-versions/<BotVersionId>/activation`
   body `{"status":"Active"}`.
8. **Bot auto-creation:** deploying the classic planner bundle auto-creates Bot
   `MyOrgButler` v1. The script publish adds versions onto the same Bot — no name clash.

## Phase 2 — Deterministic refactor (next up)

Replace prompt hacks with language constructs:

| Classic hack | Agent Script construct |
|---|---|
| "LoadCustomInstructions MUST be FIRST action" | deterministic `run @actions.LoadCustomInstructions` + `set @variables.custom_instructions` before reasoning; inject via `{!@variables.custom_instructions}` |
| Planner attributeMappings for customInstructions | `set @variables.custom_instructions = @outputs.customInstructions` on load AND store |
| "ALWAYS ExploreOrgSchema FIRST — never guess __c names" | gate: `query_records_with_soql` `available when @variables.org_schema_explored == True` |
| "MUST ExploreDataCloud BEFORE QueryDataCloud/SearchDataLibrary" | same gating with `dc_schema_explored` flag |
| "NOT for: ..." negative routing in 16 action descriptions | subagent split with small toolsets: `data`, `data_cloud`, `org_dev`, `files_web`, `memory`, `automation`; router in `start_agent` |
| "NEVER create another plan from here" (headless rules) | dedicated `automation` subagent, rules only visible after transition |
| Turn-1 gap: memory content not surfaced on "what do you know about me" | instruction tuning in `memory` subagent |

Syntax authority: `trailheadapps/agent-script-recipes` → `.airules/AGENT_SCRIPT.md`
(850-line rulebook). Block order: config → variables → system → start_agent → subagents.
Booleans `True`/`False`. 3-space indent. `...` = LLM slot-fill.

## Phase 3 — Eval parity

- Testing Center: `sf agent test run --api-name Regression` (14 cases, subjectName
  MyOrgButler works unchanged). Do NOT delete bot versions while a run is in flight —
  it kills the evaluation job ("Invalid AiEvaluation identifier").
- Multi-turn: `agent-eval/demo-story.yaml` + `prompt-regression.yaml` over the REST
  endpoint (fact 4). File-context turns need CONTENT_DOCUMENT_ID from `agent-eval/.env`.
- Data Cloud cases need the library indexed: chunk entity in THIS org is
  `ADL_X4rDl_MyOrgButl_chunk__dlm` (name is org-specific, never hardcode).

## Phase 4 — Packaging (lwc-agentscript-viewer)

Official ISV pattern ([forcedotcom/lwc-agentscript-viewer](https://github.com/forcedotcom/lwc-agentscript-viewer)):
- Vendor `lwc/agentscriptViewer/` + `staticresources/agentscriptParser` (prebuilt ~43 KB)
  into force-app (2GP).
- Ship the `.agent` content as a plain-text static resource; sync script keeps it
  identical to the bundle source (CI check on divergence).
- Wrapper LWC + setup tab: renders script, Copy button (`actions` slot); subscriber admin
  pastes into Agent Studio.
- Namespace caveat: packaged copy needs `apex://aquiva_os__Class` +
  `"Input:aquiva_os__..."` targets — sync script injects the prefix (inverse of the
  strip-deploy-restore pattern). Verify against a real packaged install before release.

## Phase 5 — README

"Two implementations, one agent": directory map, determinism mapping table, packaging
story, run commands for both worlds.

## Open items

- [x] Version cleanup: UI deletion of bot versions works where the API refuses; fresh publish is active
- [ ] Re-upload policy.pdf in Data Library UI (chunk table is empty → turn 4 / DC evals)
- [ ] Bug report forcedotcom/cli: zero-input action = runtime-invalid config passes validate+publish
- [ ] Phase 2 refactor, then re-run both eval layers
