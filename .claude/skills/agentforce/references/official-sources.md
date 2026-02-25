# Official Documentation Sources

The canonical reference for Agent Script is the Salesforce developer documentation.
Always fetch from here when in doubt — these pages are authoritative and kept up to date.

Base URL: `https://developer.salesforce.com/docs/ai/agentforce/guide/`

## Agent Script Language

| Topic | URL |
|-------|-----|
| **Overview** | https://developer.salesforce.com/docs/ai/agentforce/guide/agent-script.html |
| **Language Characteristics** | https://developer.salesforce.com/docs/ai/agentforce/guide/ascript-lang.html |
| **Blocks (File Structure)** | https://developer.salesforce.com/docs/ai/agentforce/guide/ascript-blocks.html |
| **Flow of Control** | https://developer.salesforce.com/docs/ai/agentforce/guide/ascript-flow.html |
| **Examples** | https://developer.salesforce.com/docs/ai/agentforce/guide/ascript-example.html |
| **Manage Agents** | https://developer.salesforce.com/docs/ai/agentforce/guide/ascript-manage.html |

## Agent Script Reference

| Topic | URL |
|-------|-----|
| **Reasoning Instructions** | https://developer.salesforce.com/docs/ai/agentforce/guide/ascript-ref-instructions.html |
| **Variables** | https://developer.salesforce.com/docs/ai/agentforce/guide/ascript-ref-variables.html |
| **Conditional Expressions** | https://developer.salesforce.com/docs/ai/agentforce/guide/ascript-ref-expressions.html |
| **Operators** | https://developer.salesforce.com/docs/ai/agentforce/guide/ascript-ref-operators.html |
| **Actions** | https://developer.salesforce.com/docs/ai/agentforce/guide/ascript-ref-actions.html |
| **Tools (Reasoning Actions)** | https://developer.salesforce.com/docs/ai/agentforce/guide/ascript-ref-tools.html |
| **Utils** | https://developer.salesforce.com/docs/ai/agentforce/guide/ascript-ref-utils.html |
| **Before/After Reasoning** | https://developer.salesforce.com/docs/ai/agentforce/guide/ascript-ref-before-after-reasoning.html |

## Agent Script Patterns

| Pattern | URL |
|---------|-----|
| **Guiding Principles** | https://developer.salesforce.com/docs/ai/agentforce/guide/ascript-patterns.html |
| **Action Chaining** | https://developer.salesforce.com/docs/ai/agentforce/guide/ascript-patterns-action-chaining.html |
| **Conditionals** | https://developer.salesforce.com/docs/ai/agentforce/guide/ascript-patterns-conditionals.html |
| **Fetch Data** | https://developer.salesforce.com/docs/ai/agentforce/guide/ascript-patterns-fetch-data.html |
| **Filtering (available when)** | https://developer.salesforce.com/docs/ai/agentforce/guide/ascript-patterns-filtering.html |
| **Required Topic Workflow** | https://developer.salesforce.com/docs/ai/agentforce/guide/ascript-patterns-required-flow.html |
| **Resource References** | https://developer.salesforce.com/docs/ai/agentforce/guide/ascript-patterns-resource-references.html |
| **System Overrides** | https://developer.salesforce.com/docs/ai/agentforce/guide/ascript-patterns-system-overrides.html |
| **Topic Selector** | https://developer.salesforce.com/docs/ai/agentforce/guide/ascript-patterns-topic-selector.html |
| **Transitions** | https://developer.salesforce.com/docs/ai/agentforce/guide/ascript-patterns-transitions.html |
| **Variables** | https://developer.salesforce.com/docs/ai/agentforce/guide/ascript-patterns-variables.html |

## Agentforce DX

| Topic | URL |
|-------|-----|
| **Build Agents with DX** | https://developer.salesforce.com/docs/ai/agentforce/guide/agent-dx.html |
| **Agent Metadata** | https://developer.salesforce.com/docs/ai/agentforce/guide/agent-dx-metadata.html |
| **Test with DX** | https://developer.salesforce.com/docs/ai/agentforce/guide/agent-dx-test.html |

## Testing API

| Topic | URL |
|-------|-----|
| **Overview** | https://developer.salesforce.com/docs/ai/agentforce/guide/testing-api.html |
| **Getting Started** | https://developer.salesforce.com/docs/ai/agentforce/guide/testing-api-get-started.html |
| **Considerations** | https://developer.salesforce.com/docs/ai/agentforce/guide/testing-api-considerations.html |
| **Build Tests (Metadata API)** | https://developer.salesforce.com/docs/ai/agentforce/guide/testing-api-build-tests.html |
| **Run Tests (Connect API)** | https://developer.salesforce.com/docs/ai/agentforce/guide/testing-api-connect.html |

## Recipe Repository

| Resource | URL |
|----------|-----|
| **Recipe Site** | https://developer.salesforce.com/sample-apps/agent-script-recipes/getting-started/overview |
| **GitHub Repo** | https://github.com/trailheadapps/agent-script-recipes |
| **HelloWorld** | https://developer.salesforce.com/sample-apps/agent-script-recipes/language-essentials/hello-world |
| **ActionDefinitions** | https://developer.salesforce.com/sample-apps/agent-script-recipes/action-configuration/action-definitions |
| **MultiTopicNavigation** | https://developer.salesforce.com/sample-apps/agent-script-recipes/architectural-patterns/multi-topic-navigation |
| **ErrorHandling** | https://developer.salesforce.com/sample-apps/agent-script-recipes/architectural-patterns/error-handling |
| **BidirectionalNavigation** | https://developer.salesforce.com/sample-apps/agent-script-recipes/architectural-patterns/bidirectional-navigation |
| **AdvancedInputBindings** | https://developer.salesforce.com/sample-apps/agent-script-recipes/action-configuration/advanced-input-bindings |

## Verification Decision Tree

When something doesn't work, fetch the right page:

```
Something doesn't work
├─ Syntax/structure error       → Blocks + Language Characteristics
├─ Action not running           → Actions + Tools reference
├─ Variable not updating        → Variables reference (mutable? linked?)
├─ Topic transition wrong       → Utils + Transitions pattern
├─ Lifecycle timing issue       → Before/After Reasoning + Flow of Control
├─ Conditional not evaluating   → Conditional Expressions + Operators
├─ Guard clause not working     → Filtering pattern + Tools reference
├─ Deployment/publish issue     → Agentforce DX + known-issues.md
├─ Test setup/execution         → Testing API pages + DX Test page
├─ Need a working pattern       → Patterns section (pick closest match)
└─ Need a working example       → Examples page + closest recipe
```
