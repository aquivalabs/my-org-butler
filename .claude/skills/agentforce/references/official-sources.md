# Official Documentation Sources

Fetch these URLs to verify when the condensed guide isn't enough or something doesn't work.

## Primary References

| Topic | URL |
|-------|-----|
| **Agent Script Overview** | https://developer.salesforce.com/docs/ai/agentforce/guide/agent-script.html |
| **Blocks (File Structure)** | https://developer.salesforce.com/docs/ai/agentforce/guide/ascript-blocks.html |
| **Flow of Control** | https://developer.salesforce.com/docs/ai/agentforce/guide/ascript-flow.html |
| **Actions** | https://developer.salesforce.com/docs/ai/agentforce/guide/ascript-ref-actions.html |
| **Variables** | https://developer.salesforce.com/docs/ai/agentforce/guide/ascript-ref-variables.html |
| **Tools (Reasoning Actions)** | https://developer.salesforce.com/docs/ai/agentforce/guide/ascript-ref-tools.html |
| **Utils** | https://developer.salesforce.com/docs/ai/agentforce/guide/ascript-ref-utils.html |
| **Reasoning Instructions** | https://developer.salesforce.com/docs/ai/agentforce/guide/ascript-ref-instructions.html |
| **Conditional Expressions** | https://developer.salesforce.com/docs/ai/agentforce/guide/ascript-ref-expressions.html |
| **Before/After Reasoning** | https://developer.salesforce.com/docs/ai/agentforce/guide/ascript-ref-before-after.html |
| **Operators** | https://developer.salesforce.com/docs/ai/agentforce/guide/ascript-ref-operators.html |
| **Topics** | https://developer.salesforce.com/docs/ai/agentforce/guide/ascript-ref-topics.html |
| **Examples** | https://developer.salesforce.com/docs/ai/agentforce/guide/ascript-example.html |
| **Agentforce DX** | https://developer.salesforce.com/docs/ai/agentforce/guide/agent-dx.html |

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

```
Something doesn't work
├─ Syntax/structure → Blocks + specific element reference
├─ Action not running → Actions + Tools reference
├─ Variable not updating → Variables reference (mutable? linked?)
├─ Topic transition wrong → Utils + Tools reference
├─ Lifecycle timing → Before/After Reasoning + Flow of Control
├─ Conditional not evaluating → Conditional Expressions + Operators
├─ Deployment issue → Agentforce DX
└─ Need working example → Closest matching recipe
```

## URL Fallback

Docs exist under two paths (both may work):
- `developer.salesforce.com/docs/einstein/genai/guide/ascript-*` (older beta path)
- `developer.salesforce.com/docs/ai/agentforce/guide/ascript-*` (current path)

If one 404s, try the other prefix. If both fail, web-search `site:developer.salesforce.com agent script <topic>`.
