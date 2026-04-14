# Manual Org Setup Steps

Complete these steps when the org opens during scratch org creation.

## 1. Enable Agent Analytics & Session Tracing

- Setup → search "Audit" → Einstein Generative AI
- Turn on **Agent Analytics**
- Turn on **Agentforce Session Tracing**
- Agent Optimization turns on automatically

This provisions the session tracing data model in Data Cloud (`ssot__AiAgent*__dlm` entities).

## 2. Hybrid Search Index on Agent Conversations

- Data Cloud → Search Index → New → Advanced Setup
- Search Type: **Hybrid Search**
- Source Object: **AI Agent Interaction Message** (`ssot__AiAgentInteractionMessage__dlm`)
- Chunking fields: only **Content** (`ssot__ContentText__c`)
- Chunking strategy: Passage Extraction, 512 tokens
- Vectorization: E5 Large V2
- Save & Build

This enables semantic search on agent conversation history via `hybrid_search()`.

## 3. Data Library

- Setup → Data Library
- Create a new Data Library named: **MyOrgButlerLibrary**
- Type: File
- Upload: `scripts/policy.pdf` (company sales policy with discount thresholds — print from `scripts/policy.md`)
- Create a search index and wait for it to complete

## 4. Tavily API Key (for web search)

- If not already configured, add your Tavily API key to the TavilyApi external credential
