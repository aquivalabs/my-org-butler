# My Org Butler

## Coding Standards

Follow [AGENTS.md](AGENTS.md) strictly for all coding patterns, naming conventions, and test structures.

## Project Context

Open-source Salesforce Agentforce assistant. General-purpose AI butler for any Salesforce org - queries data, searches the web, manages files, edits metadata, and integrates with GitHub.

**Reference Implementation**: Atamis Agentforce at `/Users/rsoesemann/dev/aquivalabs/atamis-agentforce`

## Domain Model

| Object | Purpose |
| ------ | ------- |
| `Memory__c` | Agent memory storage for learning and recall |
| `CustomSetting__c` | User-specific custom instructions |

## Key Locations

| Component | Location |
| --------- | -------- |
| Apex classes | `force-app/main/default/classes/` |
| Prompt Templates | `force-app/main/default/genAiPromptTemplates/` |
| GenAI Functions | `force-app/main/default/genAiFunctions/` |
| GenAI Plugins | `force-app/main/default/genAiPlugins/` |
| Agent Tests | `regressions/aiEvaluationDefinitions/` |
| Learnings | `docs/claude-code-learnings.md` |

## Workflow

**Every code change must be deployed and tested.** Local changes mean nothing in Salesforce.

## Deploying Agent Tests

Agent tests (AiEvaluationDefinitions) require the agent to be deactivated before deployment:

```bash
# 1. Deactivate agent
sf agent deactivate --api-name MyOrgButler

# 2. Deploy test definitions
sf project deploy start --source-dir regressions --concise --ignore-conflicts

# 3. Reactivate agent
sf agent activate --api-name MyOrgButler

# 4. Reset sample data
sf apex run --file scripts/create-sample-data.apex

# 5. Run tests
sf agent test run --api-name Research_Test --wait 10
sf agent test run --api-name Act_Test --wait 10
sf agent test run --api-name Configure_Test --wait 10
```

## Agentforce Patterns

**Architecture**: `User → genAiPlugin → genAiFunction → Apex Action → [optional] genAiPromptTemplate`

**When to use what**:

- Apex Only: CRUD, calculations, API calls
- Prompt Template: AI analysis/generation
- Both: Query data + AI analysis

**Prompt Template Activation**: Deploy AND activate in Prompt Builder UI. "Published" status is NOT enough.

**Plugin Instructions**: Keep short. No ALWAYS/NEVER/CRITICAL. Trust the model. See existing plugins.

**Agent Tests**: Non-deterministic. Run 3x to establish baseline. Topic should be 100%, actions may vary.

## Plugin Architecture (4 plugins)

| Plugin | Purpose | Functions |
| ------ | ------- | --------- |
| Research | Find information from any source | QueryRecordsWithSoql, RetrieveVectorizeChunks, SearchWeb |
| Act | Create, update, delete records | CallRestApi |
| Configure | Understand and modify metadata | ExploreOrgSchema, CallMetadataApi, CallToolingApi |
| Integrate | External system integrations | CallGitHubApi |

## Code Scanner

```bash
sf code-analyzer run --rule-selector "Recommended:Security" "AppExchange" "flow" "sfge" --output-file security-review/scans/code-analyzer-security.csv --target force-app/main/default
sf code-analyzer run --rule-selector "PMD:OpinionatedSalesforce" --output-file security-review/scans/code-analyzer-cleancode.csv --target force-app/main/default
```

## Skills

`/apex-test-cycle`, `/agent-test-cycle`, `/deploy-and-troubleshoot`
