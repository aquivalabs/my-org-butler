# My Org Butler — Agent Script Migration

This repo is mid-migration from classic Agentforce metadata to **Agent Script**.
Branch: `migration-to-agent-script-v2`. This file describes the current state and plan —
nothing else. Coding standards live in `.claude/rules/`.

## Architecture (current)

- **The agent** is `force-app/main/default/aiAuthoringBundles/MyOrgButler/MyOrgButler.agent`
  (AiAuthoringBundle). One subagent (`butler`), 18 actions: 15 Apex (`apex://<Class>`),
  1 prompt template (`generatePromptResponse://AnswerFromFile`), 2 standard actions
  (`EmployeeCopilot__IdentifyRecordByName`, `EmployeeCopilot__GetRecordDetails`).
  This is the naive 1:1 port of the classic agent — deliberately including its
  prompt-engineering guardrails ("MUST be FIRST", "NOT for: ...").
- **Classic agent metadata** is deleted from the working tree (also the classic Bot/
  GenAiPlannerBundle copies that lived in `unpackaged/` — they broke fresh-org deploys
  once the plugins were gone). Git tag `pre-agent-script-migration` marks the last
  commit with the full classic implementation.
- Deploy → publish → activate: deploying the bundle only stores source in the org.
  `sf agent publish authoring-bundle --api-name MyOrgButler --skip-retrieve` compiles it
  into Bot/BotVersion/GenAiPlannerBundle; activation makes it runnable.
  `scripts/create-scratch-org.sh` does all of this.

## Remaining phases

1. **Deterministic refactor** (next): replace prompt hacks with language constructs —

   | Classic hack | Agent Script construct |
   |---|---|
   | "LoadCustomInstructions MUST be FIRST action" | `run @actions.LoadCustomInstructions` + `set @variables.custom_instructions` before reasoning |
   | Planner attributeMappings | `set @variables.… = @outputs.…` on load AND store |
   | "ALWAYS ExploreOrgSchema/ExploreDataCloud FIRST" | `available when @variables.…_explored == True` gates |
   | "NOT for: …" negative routing in descriptions | subagent split (`data`, `data_cloud`, `org_dev`, `files_web`, `memory`, `automation`) + router |
   | Headless "NEVER create another plan" rules | dedicated `automation` subagent, visible only after transition |

   Known agent bugs this must fix (from test runs): claims "Noted" without calling
   StoreCustomInstruction; answers memory questions without calling LoadCustomInstructions;
   doesn't surface memory content.
   Syntax authority: `trailheadapps/agent-script-recipes` → `.airules/AGENT_SCRIPT.md`.
2. **Packaging** via [forcedotcom/lwc-agentscript-viewer](https://github.com/forcedotcom/lwc-agentscript-viewer):
   AiAuthoringBundle is NOT 2GP-packageable. Ship the `.agent` as text in a static
   resource + vendored viewer LWC + setup page; subscriber admin copies into Agent Studio.
   Namespace caveat: packaged copy needs `apex://aquiva_os__…` targets (sync script
   injects prefix; unverified against a real install).
3. **README** showcase: "one agent, two implementations".

## Testing

Everything lives in `agent-eval/`. All on the **Agentforce Studio (NGT) test runner**
(Beta — the legacy AiEvaluationDefinition flow is officially "legacy" and was deleted here):

- `aiTestingDefinitions/AgentRegression.aiTestingDefinition-meta.xml` — 14
  per-action cases. Run: `sf agent test run --api-name AgentRegression --wait 30`.
- `aiTestingDefinitions/PromptRegression.aiTestingDefinition-meta.xml` —
  prompt-template smoke tests (ConsolidateMemory via conversationHistory, AnswerFromFile).
- `demo-story.yaml` — the multi-turn conference-demo conversation, driven over the REST
  endpoint below, judged by Claude in-memory. Covers what single-turn can't.

NGT format facts: testCases have `inputs:` (utterance + optional contextVariables /
conversationHistory — **every** history turn needs a `topic`, even user turns) and
`scorers:` (topic_sequence_match, action_sequence_match, agent_handoff_match,
bot_response_rating, response_match, coherence, conciseness, factuality, completeness,
task_resolution, output_latency_milliseconds). Label/description max 80 chars.
The CLI returns actual/expected pairs but **no pass/fail verdicts** — grade yourself or
in the Studio UI. YAML specs are transient: `sf agent generate test-spec
--from-definition <xml>` ⇄ `sf agent test create --spec <yaml> --test-runner
agentforce-studio`. Repo keeps only the XML.

Smoke-test channel (works for classic and script agents):

    POST /services/data/v66.0/actions/custom/generateAiAgentResponse/MyOrgButler
    {"inputs":[{"userMessage":"...", "sessionId":"<from previous response>"}]}

## Platform gotchas (expensive to learn — don't re-learn)

1. **Zero-input actions break the runtime.** Compiles + publishes fine, then every session
   throws `InvalidPlannerConfigException`. Fix: dummy optional input (`ignored: string`).
2. **`sf agent publish` finds bundles only in the DEFAULT package directory** (validate
   searches all) — hence `force-app` is `"default": true`.
3. **`sf agent preview --api-name` can't start Employee-agent sessions**
   ([forcedotcom/cli#3608](https://github.com/forcedotcom/cli/issues/3608)); use
   `--authoring-bundle` or the REST endpoint above.
4. **`versionTag` in bundle-meta.xml is dead metadata** — publish never reads it; Builder
   version labels are the Builder's own counter. We removed it.
5. **Published bot versions are undeletable via API** (locked by AiAuthoringBundleDefVer);
   the Studio UI can delete them. Don't delete versions while a test run is in flight.
6. Version activation without the interactive picker:
   `POST /connect/bot-versions/<Id>/activation` body `{"status":"Active"}`.
7. **`sf agent adl file add` uploads but never triggers indexing** — kick
   `POST /einstein/data-libraries/<libId>/indexing` with
   `{"uploadedFiles":[{"filePath":"$agentforce_data_library$/<libId>/<file>","fileSize":<bytes>}]}`
   or files sit unindexed forever. `create-scratch-org.sh` does this automatically.
8. **Data Cloud entity names are org-specific** (`ADL_<random>_…_chunk__dlm`) — never
   hardcode them in tests or code; the agent discovers them via ExploreDataCloud.
9. AiTestingDefinition records with run history can't be deleted via API — Studio UI only.

## Deploying

Never `sf project deploy start --source-dir force-app` against a namespaced target without
the namespace strip. The scratch org is namespaceless; `create-scratch-org.sh` strips
`aquiva_os__` before deploying and restores afterwards. For single files:

    sed -i 's/aquiva_os__//g' <file> && \
      sf project deploy start --source-dir <file> --concise; \
      git checkout -- <file>

## Open items

- [ ] **Store bug**: the router LLM sometimes answers preference statements itself instead
      of transitioning to the butler, so StoreCustomInstruction is never called (failing:
      AgentRegression case 14, PromptRegression case 1). Fix: make routing deterministic —
      end the router's `instructions:->` procedure with `transition to @subagent.butler`
      and remove the `begin_butler` reasoning action. If the compiler rejects a transition
      directive there, use an unconditional `after_reasoning: transition to @subagent.butler`.
      Then publish, activate, rerun AgentRegression + PromptRegression + demo story.
- [ ] Test cleanup: AgentRegression case "show me my stored preferences" and the same case
      in PromptRegression carry an action scorer with an empty expectedValue — remove the
      scorer or set it to `LoadCustomInstructions`.

- [ ] Zombie org-side suites `RegressionStudio`, `OrgButlerRegression`,
      `MyOrgButlerPromptTemplates` — undeletable via API (run history), invisible in
      Studio UI; clean up when possible or ignore until org rebuild
- [ ] Demo-story fully green once Data Library chunks are indexed
- [ ] Phase 1 (deterministic refactor) → Phase 2 (packaging) → Phase 3 (README)
- [ ] Bug reports against forcedotcom/cli: zero-input action config passes
      validate+publish but breaks runtime; `adl file add` never triggers indexing
- [ ] **Data Library chunking broken since 2026-07-22**: files upload and every
      pipeline stage reports SUCCESS/READY/"Indexed", but chunk DMOs stay at 0 rows —
      CLI, REST and manual Studio UI creation all affected. Salesforce switched the
      index pipeline org-side that day (new indexes get GPT-4o
      `pre_process_infographics_using_llm` + `e5_large_v2`; older ones had no
      preprocessing + `multilingual-e5-large`). Suspect the LLM preprocessing step
      fails silently for PDFs in scratch orgs. Untested workaround: upload `.txt`
      (bypasses preprocessing). Diagnose with `sf agent adl status --include-artifacts`
      and `/services/data/v66.0/ssot/search-index`.
