# Manual Org Setup Steps

Complete these steps when the org opens during scratch org creation.

## 1. Tavily API Key (for web search)

- If not already configured, add your Tavily API key to the TavilyApi external credential

## 2. Verify Data Cloud is provisioned

- Setup → Data Cloud → Overview
- If not provisioned yet, wait — it can take a few minutes after scratch org creation
- Do not proceed until the Data Cloud overview page loads successfully

## 3. Enable Agent Analytics & Session Tracing

- Setup → search "Audit" → Einstein Generative AI
- Turn on **Agent Analytics**
- Turn on **Agentforce Session Tracing**
- Agent Optimization turns on automatically

This provisions the session tracing data model in Data Cloud (`ssot__AiAgent*__dlm` entities).

## 4. Data Library

- Setup → Data Library
- Create a new Data Library named: `MyOrgButlerLibrary`
- Type: File
- Upload: `scripts/policy.pdf` (company sales policy with discount thresholds — print from `scripts/policy.md`)
- Create a search index and wait for it to complete
