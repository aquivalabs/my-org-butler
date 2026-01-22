# What My Org Butler Can Learn from Claude Code

**Author:** Analysis based on [Decoding Claude Code](https://minusx.ai/blog/decoding-claude-code/)
**Date:** January 2026
**Context:** Improving AgentForce agents by applying patterns from Claude Code's architecture

---

## Executive Summary

Claude Code, Anthropic's CLI coding assistant, has proven remarkably effective despite its architectural simplicity. This document analyzes what makes Claude Code work and proposes a **radical restructuring** of My Org Butler based on those learnings.

**Key insight:** Claude Code's success comes not from advanced RAG, complex multi-agent orchestration, or sophisticated reasoning frameworks—but from **trusting the model more and instructing it less**.

**The radical proposal:** Reduce 7 plugins to 4. Cut instructions by 75%. Replace rules with examples.

---

## The Surprising Simplicity of Claude Code

### What Claude Code Doesn't Do

- No complex multi-agent handoffs
- No elaborate RAG pipelines with rerankers and chunking strategies
- No hidden abstraction layers
- No "smart" routing between specialized models

### What Claude Code Does Instead

1. **Single-loop architecture** - One main thread with flat message history
2. **Structured prompts** - Explicit heuristics, decision algorithms, contrasting examples
3. **Versatile tools** - A small set of powerful, general-purpose tools
4. **Progressive disclosure** - Core instructions always present, details on-demand

---

## Architecture Comparison

| Aspect | Claude Code | My Org Butler |
|--------|-------------|---------------|
| Topic organization | Plugins/Skills | GenAiPlugins (Topics) |
| Base tools | Bash, Read, Write, Grep, Edit, WebFetch | SOQL, REST API, Metadata API, Tooling API, Web Search |
| Memory system | claude.md + context files | Memory__c + customInstructions |
| Prompt format | Markdown with YAML frontmatter | XML with genAiPluginInstructions |
| Agent loop | Single ReAct loop | AiCopilot__ReAct |

**The structures are remarkably similar.** Both use:
- Modular topics that activate based on user intent
- A small set of versatile, composable tools
- A memory system for persistent preferences
- Topic-level instructions that guide behavior

---

## What My Org Butler Already Does Well

### 1. Strong Topic Modularization
Seven well-scoped plugins matching Claude Code's skill pattern:
- AnswerWithData (SOQL queries)
- AnswerWithExternalContent (vector search)
- AnswerWithFiles (document analysis)
- AnswerWithInternet (web search)
- EditData (CRUD operations)
- ExploreAndEditMetadata (schema and config)
- ManageGitHub (repository management)

### 2. Versatile Base Tools
The actions are powerful and composable:
- `ExploreOrgSchema` - Discover objects, fields, relationships
- `QueryRecordsWithSoql` - Flexible data queries
- `CallRestApi` - Generic CRUD operations
- `CallMetadataApi` / `CallToolingApi` - Configuration changes

### 3. Excellent ManageGitHub Plugin
This plugin already follows Claude Code patterns:
- Step-by-step workflow heuristics
- "Synthesize, Do Not List" principle
- "Hide the Plumbing" guidance
- Explicit decision trees for ambiguous situations

### 4. Memory System
The LoadCustomInstructions/StoreCustomInstruction pattern mirrors Claude Code's approach to learning user preferences.

---

## Key Patterns from Claude Code

### Pattern 1: Emphasis Markers

Claude Code uses explicit markers for high-stakes instructions:

```markdown
**CRITICAL:** This must be followed or the task will fail
**NEVER:** Forbidden actions that should never occur
**ALWAYS:** Required actions for every response
**IMPORTANT:** High-priority guidance
```

These markers stand out in the prompt and are easier for models to follow than buried prose.

### Pattern 2: Good/Bad Example Pairs

Claude Code consistently shows what TO do and what NOT to do:

```markdown
<good-example>
"You have 3 open opportunities totaling $150K. The largest is
Acme Corp at $50K, closing next week."
</good-example>

<bad-example>
"Here are the results: [JSON dump of 47 fields per record]"
</bad-example>
```

Contrasting examples are more effective than rules alone.

### Pattern 3: "Synthesize, Don't List"

From Claude Code's system prompt:
> "Your primary goal is to provide insights, not raw data dumps. Raw lists of commits or files are not acceptable responses. You must process the data and provide a summary."

Users want answers, not data.

### Pattern 4: "Hide the Plumbing"

From the ManageGitHub plugin:
> "Do not expose commit hashes, issue numbers, or raw API responses unless explicitly asked."

Users shouldn't see the internal mechanics—SOQL queries, API calls, technical field names.

### Pattern 5: Explicit Decision Algorithms

Instead of vague guidance, Claude Code provides explicit if/then logic:

```markdown
**If one clear result is found:** Extract owner and repo, proceed to next step
**If multiple results are found:** List top 2-3 options and ask user to choose
**If no results are found:** Inform user and stop
```

### Pattern 6: Workflow Phases

Complex tasks are broken into numbered phases with clear goals:

```markdown
## Phase 1: Discovery
**Goal**: Understand what needs to be built

## Phase 2: Exploration
**Goal**: Understand existing code patterns

## Phase 3: Clarifying Questions
**Goal**: Fill in gaps before designing
```

---

## Specific Improvement Opportunities

### AnswerWithInternet (Needs Most Work)

**Current state:** Only 4 bullet points, very sparse instructions.

**Proposed improvements:**
- Add full workflow (reformulate → search → evaluate → synthesize)
- Add synthesis examples showing narrative answers vs. link dumps
- Add source citation patterns
- Add error handling (no results, conflicting sources)

### AnswerWithData (High Impact)

**Current state:** Good foundation, but missing output formatting guidance.

**Proposed improvements:**
- Add "Transform data into insights" principle with examples
- Add "Hide the Plumbing" section (never show SOQL, use field labels)
- Add error recovery heuristics

### EditData (Safety Critical)

**Current state:** Functional but lacks safety confirmations.

**Proposed improvements:**
- Add confirmation patterns before modifications
- Add bulk operation safety (always confirm count first)
- Add user-friendly error explanations

### Cross-Cutting Issue: Duplicated Instructions

The "Proactive Learning" and "Applying Preferences" sections are **identical** across all 7 plugins (~40 lines each × 7 = 280 lines of duplication).

Additionally, the examples in these sections are always about Opportunities—even in the ManageGitHub plugin where repository examples would be more relevant.

---

## Implementation Recommendations

### Priority 1: AnswerWithInternet
Rewrite from scratch with proper workflow, synthesis guidance, and source citation.

### Priority 2: AnswerWithData
Add output formatting and "Hide the Plumbing" sections.

### Priority 3: EditData
Add safety confirmation patterns.

### Priority 4: Standardization
- Use consistent emphasis markers across all plugins
- Make learning examples plugin-specific
- Consider extracting duplicated sections

---

## Testing Recommendations

After implementing changes, test with these scenarios:

| Plugin | Test Query | Expected Behavior |
|--------|-----------|-------------------|
| AnswerWithInternet | "What's new in Salesforce Winter '25?" | Synthesized narrative with source citations |
| AnswerWithData | "Show me my opportunities" | Narrative summary with record links, no JSON |
| EditData | "Update all contacts" | Confirmation prompt before any changes |
| ExploreAndEditMetadata | "Explain the Case object" | Relationship narrative, not field list |

---

## WAIT: A Critical Re-Assessment

The recommendations above were my first analysis. But they're **wrong**.

After deeper reflection: **more instructions made My Org Butler worse, not better**.

The real lesson from Claude Code isn't about emphasis markers or detailed workflows. It's about **trusting the model** and **showing examples instead of writing rules**.

---

# Part 2: The Radical Proposal

## The Problem with the Current Plugin Structure

### Claude Code organizes by TASK

```
/commit      → Create a commit
/feature-dev → Build a feature
/pr-review   → Review code
```

The user thinks: "I want to commit" → skill activates.

### My Org Butler organizes by DATA SOURCE

```
AnswerWithData            → Query Salesforce
AnswerWithExternalContent → Search vector DB
AnswerWithFiles           → Read attachments
AnswerWithInternet        → Web search
```

The user thinks: "What's the Acme project status?"

**But where IS that information?** Salesforce? Confluence? An attached doc? The user doesn't know and shouldn't need to know.

**The current structure leaks implementation details.**

---

## What Users Actually Want

Users don't think in data sources:

| User Intent | Current Plugin | Problem |
|-------------|----------------|---------|
| "What's the project status?" | ??? | Could be any of 4 "Answer" plugins |
| "Update this contact" | EditData | Why separate from querying? |
| "Explain our data model" | ExploreAndEditMetadata | OK |
| "What changed in our repo?" | ManageGitHub | OK |

The 4 "Answer" plugins create confusion. The agent must guess which source to use.

---

## The Real Lesson: Less Rules, More Examples

Looking at actual Claude Code prompts:

**What they DON'T do:**
- Long lists of rules
- Emphasis markers everywhere
- Step-by-step workflows for every scenario

**What they DO:**
- Provide context
- Show 2-3 clear examples
- Trust the model to figure out the rest

Claude Code's `/commit` command is **17 lines**. My Org Butler's plugins have **80-100+ lines each**.

---

## The Radical Restructuring

### From 7 plugins → 4 plugins

| Old | New | Purpose |
|-----|-----|---------|
| AnswerWithData | **Research** | Find information from ANY source |
| AnswerWithExternalContent | *(merged)* | |
| AnswerWithFiles | *(merged)* | |
| AnswerWithInternet | *(merged)* | |
| EditData | **Act** | Create, update, delete records |
| ExploreAndEditMetadata | **Configure** | Understand and modify metadata |
| ManageGitHub | **Integrate** | External system integrations |

---

## New Plugin Instructions (Radically Simplified)

### Research Plugin (~20 lines total)

```
## YOUR JOB

Find information and answer questions. You have access to:
- Salesforce records (SOQL)
- Company documentation (vector search)
- Files attached to records
- The web

Choose the right source. Often you'll need multiple. Synthesize into a clear answer.

## OUTPUT STYLE

<example>
User: "What's the Acme project status?"
You: "Acme is 60% complete, on track for March 15 go-live.
Last milestone (Design Review) closed Jan 10.
The SOW shows $150K budget with $90K invoiced.
[View Project] [View SOW]"
</example>

Never dump raw data. Never show queries. Give insights with links.
```

**That's it.** One clear example. One constraint. Trust the model.

### Act Plugin (~15 lines total)

```
## YOUR JOB

Create, update, or delete Salesforce records when the user asks.

## CONFIRM BEFORE ACTING

<example>
User: "Mark all my overdue tasks complete"
You: "I found 5 overdue tasks. I'll mark them Complete:
- Follow up with Acme (due Jan 5)
- Send proposal (due Jan 8)
- [3 more]
Proceed?"
</example>

Always confirm bulk changes. Report success with record links.
```

### Configure Plugin (~20 lines total)

```
## YOUR JOB

Help users understand and modify their Salesforce configuration.

## OUTPUT STYLE

<example>
User: "Explain the Project data model"
You: "Projects connect like this:
Account → Project__c → Milestone__c → Time_Entry__c

A Project belongs to one Account. Each Project has Milestones
with due dates. Time Entries track hours against Milestones.

[View Diagram]"
</example>

Explain relationships narratively. Link to records. Offer diagrams.
```

### Integrate Plugin (~20 lines total)

```
## YOUR JOB

Help users work with GitHub: browse repos, view commits, manage issues/PRs.

## OUTPUT STYLE

<example>
User: "What changed in my-org-butler recently?"
You: "Last week's changes:

**Bug fixes:** Login redirect issue fixed, timezone display corrected
**Features:** Added bulk export for reports
**Refactoring:** Cleaned up test utilities

Most active: 12 commits from @rsoesemann"
</example>

Tell the story of what changed. Don't dump commit hashes.
```

---

## Memory Instructions (Shared, Simplified)

Currently 40 lines × 7 plugins = 280 lines of duplication.

**New version (10 lines):**

```
## LEARNING PREFERENCES

When the user corrects you or states a preference, remember it:
- "Always sort by close date" → Store for future queries
- "I prefer tables" → Store for formatting

Use StoreCustomInstruction to save. Ask "Just for you, or everyone?" if unclear.

{!customInstructions}
```

---

## Why This Will Work

1. **Clearer routing** - "Find information" is clearer than "query standard Salesforce apps"
2. **Less confusion** - One Research plugin vs. four "Answer" plugins
3. **Better synthesis** - Model can combine sources without switching plugins
4. **Shorter instructions** - Examples > rules
5. **Trust the model** - It knows how to query, search, and synthesize

---

## Migration Summary

**Create:**
- Research.genAiPlugin-meta.xml
- Act.genAiPlugin-meta.xml
- Configure.genAiPlugin-meta.xml
- Integrate.genAiPlugin-meta.xml

**Delete:**
- AnswerWithData.genAiPlugin-meta.xml
- AnswerWithExternalContent.genAiPlugin-meta.xml
- AnswerWithFiles.genAiPlugin-meta.xml
- AnswerWithInternet.genAiPlugin-meta.xml
- EditData.genAiPlugin-meta.xml
- ExploreAndEditMetadata.genAiPlugin-meta.xml
- ManageGitHub.genAiPlugin-meta.xml

**Update:**
- MyOrgButler_v1_Template.genAiPlannerBundle

---

## Testing the Changes

| Plugin | Test Query | Expected |
|--------|------------|----------|
| Research | "What's the Acme project status?" | Combines Salesforce + docs if needed |
| Research | "What's our PTO policy?" | Finds in vector DB or web |
| Act | "Update all contacts" | Confirms before bulk change |
| Configure | "Explain the Case object" | Narrative with diagram offer |
| Integrate | "What changed in the repo?" | Story of changes, not commit list |

---

## The Core Insight

| Conservative Approach | Radical Approach |
|----------------------|------------------|
| Add more emphasis markers | Remove emphasis markers |
| Add more detailed workflows | Cut workflows, show examples |
| Keep 7 plugins | Merge to 4 plugins |
| ManageGitHub is the template | ManageGitHub is over-engineered |
| Make instructions longer | Make instructions 75% shorter |

**Trust the model more. Instruct it less.**

---

---

# Part 3: Learnings from Atamis AgentForce

## Atamis vs My Org Butler Comparison

| Metric | Atamis | My Org Butler |
|--------|--------|---------------|
| Total plugin lines | 437 | 1292 |
| Plugins | 6 | 7 |
| Instruction blocks per plugin | 1 | 3-4 |
| Lines per plugin | 30-87 | 80-185 |
| Naming style | Task-oriented | Data-source-oriented |

**Atamis confirms our radical approach is right.**

---

## Atamis Plugin Naming (Task-Oriented)

```
OnboardSupplier
ConsolidateCategoryContracts
DraftTenderRequirements
RecommendTenderSuppliers
ReviewSupplierTerms
SummarizeTender
```

Every name is a **verb + noun** describing what the user wants to do.

Compare to My Org Butler's current naming:

```
AnswerWithData            → What source?
AnswerWithExternalContent → What source?
AnswerWithFiles           → What source?
AnswerWithInternet        → What source?
```

Our proposed naming is closer to Atamis:

```
Research   → Find information
Act        → Modify data
Configure  → Change settings
Integrate  → Connect external systems
```

---

## Atamis Instruction Style

**Single instruction block, procedural, numbered steps:**

```
## Process
1. Resolve Supplier Bidding record:
   - If invoked from a Supplier Bidding record page, use currentRecordId directly
   - If currentRecordId is not available: [fallback logic]
2. Check for existing supplier
3. Validate required data
4. Convert to Supplier
```

**Not** multiple conceptual blocks like My Org Butler's current:
- Block 1: General instructions
- Block 2: Proactive learning
- Block 3: Applying preferences

---

## Error Transformation Pattern (New)

Atamis explicitly maps technical errors to user-friendly messages:

```
## Error Handling
- INVALID_FIELD: "The field [X] doesn't exist on [Object]. Check field API names."
- INSUFFICIENT_ACCESS: "You don't have permission to [action]. Contact your admin."
- DUPLICATE_VALUE: "A record with this value already exists."
```

**Add this to our new plugins.**

---

## GenAiPromptTemplates (Consider for Complex Analysis)

Atamis uses separate prompt template files for complex AI analysis tasks.

**Example: DraftTenderRequirements template**
```xml
<content>
# Instructions
You are a procurement specialist. Analyze tender documents to extract requirements.

## Tender Data
{!$Input:tenderData}

## Categorize requirements:
- Technical
- Commercial
- Compliance
- Capability
</content>
```

**Consider for My Org Butler:**
- Research plugin: Complex multi-source synthesis
- Configure plugin: Schema analysis and explanation
- Integrate plugin: Commit/PR analysis

---

## Updated Recommendations

Based on both Claude Code AND Atamis learnings:

1. **Keep instructions short** (20-30 lines like Atamis, not 80-185)
2. **Single instruction block** per plugin (not 3-4)
3. **Task-oriented names** (Research, Act, Configure, Integrate)
4. **Procedural steps** for clear workflows
5. **Error transformations** for user-friendly messages
6. **Consider GenAiPromptTemplates** for complex analysis

---

---

# Part 4: The Communication Magic

## What We Initially Missed

Our first simplification focused on **structure** (7→4 plugins) and **length** (cut 75%). But we missed the **tone and communication style** that makes Claude Code feel magical.

## Claude Code's Communication Principles

From the actual system prompts and the minusx article:

### 1. Ruthless Conciseness

> "Answer concisely with fewer than 4 lines unless asked for detail."
> "One word answers are best when possible."
> "Minimize output tokens while maintaining helpfulness."

### 2. No Preamble

Never start with:
- "Let me help you with that..."
- "I'll look that up for you..."
- "Here is what I found..."

Just answer the question directly.

### 3. No Post-Action Narration

Never say:
- "Here's what I did..."
- "I've completed the task..."
- "I successfully created..."

Just confirm what changed.

### 4. No Tool Narration

Bad: "Let me use the QueryRecords function to search for your data. After analyzing the results..."
Good: "Found 5 open opportunities totaling $150K."

### 5. Good/Bad Example Pairs

Claude Code uses contrasting examples to show what TO do and what NOT to do:

```xml
<good-example>
User: "Project status?"
You: "Acme: 60% complete, on track for March 15."
</good-example>

<bad-example>
User: "Project status?"
You: "Let me look that up for you. I found the project in Salesforce. Here is what I discovered about the status..."
</bad-example>
```

## What We Added to Our Plugins

Each plugin now includes:

1. **"## How to Respond"** section with tone guidance
2. **`<good-example>` tags** showing concise responses
3. **`<bad-example>` tags** showing what to avoid
4. **Explicit anti-patterns**: "Never narrate tool calls", "Never start with 'Let me...'"

## The Core Insight

**The magic isn't the tools or structure—it's the communication style.**

Users feel delighted when:
- Responses are instant and to the point
- No unnecessary ceremony or narration
- Results feel like direct answers, not AI-generated reports

---

## References

- [Decoding Claude Code](https://minusx.ai/blog/decoding-claude-code/) - Original analysis article
- [My Org Butler Repository](https://github.com/aquivalabs/my-org-butler)
- [Claude Code Plugins](https://github.com/anthropics/claude-code) - Reference implementations
- Atamis AgentForce - Internal project confirming simpler approach
