## <img src="resources/logo.png" width="50"/> My Org Butler [`v2026.7.0`](https://github.com/aquivalabs/my-org-butler/releases/tag/v2026.7.0)

My Org Butler is a showcase for building Agentforce solutions that help Salesforce users with their daily work. It started in early 2024 on the [OpenAI Assistants API with a custom LWC frontend](../../tree/openai-agentforce-hybrid), then moved to pure Agentforce when it became powerful enough. Using natural language, it answers questions about data, metadata, and configuration, and can perform tasks like creating records, making configuration changes, or notifying other people.


### Show me a demo

[![Agentforce Demo](http://img.youtube.com/vi/_pz1rgWpDXU/hqdefault.jpg)](https://youtu.be/LuLv77KKRIo?si=-ya1wjyksBH2jZbG&t=656 "Agentforce Version")


Find all of Aquiva's My Org Butler related video demos at this [YouTube playlist](https://youtube.com/playlist?list=PL9OHq276T12G1Ngw5m05KZyY5jwF5qMLD&si=rmKXPGRYhw4Bxgs9).

---

### How to install

1. **Install Prerequisite** - Install the [latest version](https://login.salesforce.com/packaging/installPackage.apexp?p0=04tVI000000L3ZBYA0) of the [App Foundations](https://github.com/aquivalabs/app-foundations) package (prerequisite)
2. **Install My Org Butler** - Grab the latest package version ID from [sfdx-project.json](sfdx-project.json) and install via [Production](https://login.salesforce.com/packaging/installPackage.apexp?p0=04tVI000000d3IzYAI) or [Sandbox](https://test.salesforce.com/packaging/installPackage.apexp?p0=04tVI000000d3IzYAI)
3. **Enable Agentforce** in your org (if not already enabled)
4. **Create the Agent from Script** - The agent is written in [Agent Script](https://developer.salesforce.com/docs/ai/agentforce/guide/agent-script.html) and Salesforce can't package it yet. Open `<your-org-url>/resource/AgentScript` in the browser, copy the script, and paste it into a new agent in **Agent Studio** with API name `MyOrgButler`, then publish and activate it.
5. **Turn on Optional Features** (choose which capabilities you want to enable):

   **Turn on Web Search:**
   1. Get a [free Tavily API key](https://tavily.com/)
   2. Go to **Setup → Named Credentials → `TavilyApi`**
   3. Click on the linked External Credential `TavilyApi`  
   4. Create a New Named Principal with parameter name `ApiKey`
   5. Enter your Tavily API key as the value

That's it! The Butler will be available in your Agentforce sidebar.

### What can the Butler do?

The whole agent is one [Agent Script](unpackaged/main/default/aiAuthoringBundles/MyOrgButler/MyOrgButler.agent) file with **18 actions** (15 Apex, 1 prompt template, 2 standard actions). The classic implementation (topics, genAiFunctions, botTemplate metadata) lives behind the git tag [`pre-agent-script-migration`](../../tree/pre-agent-script-migration). The actions handle the Salesforce-specific work:

- Query data, metadata, and settings using [natural language SOQL](force-app/main/default/classes/QueryRecordsWithSoql.cls)
- Create and update records via the [REST API](force-app/main/default/classes/CallRestApi.cls)
- Read and modify code and configuration via the [Tooling API](force-app/main/default/classes/CallToolingApi.cls) and [Metadata API](force-app/main/default/classes/CallMetadataApi.cls)
- Generate [PlantUML diagrams](force-app/main/default/classes/CreatePlantUmlUrl.cls) for data models and processes
- [Search the web](force-app/main/default/classes/SearchWeb.cls)
- Answer questions about a file using platform-native file grounding
- [Search company documents in a Data Library](force-app/main/default/classes/SearchDataLibrary.cls) via Data Cloud hybrid search (requires Data Cloud setup — see below)
- [Notify](force-app/main/default/classes/NotifyUser.cls) people and [delegate tasks](force-app/main/default/classes/RunMyOrgButler.cls) to a headless sub-agent
- [Remember user preferences](force-app/main/default/classes/StoreCustomInstruction.cls) across conversations

### Is it safe?

**Salesforce Data: ✅ Secure** - All queries use `USER_MODE` and `with sharing`. Users only see records they have permission to access. Field-level security, object permissions, and sharing rules are fully enforced.

**Metadata & Tooling API: ✅ Permission-Gated** - Create, update, and delete operations on metadata/code require specific user permissions ("View All Data" for Tooling API, "Modify Metadata" or "Author Apex" for Metadata API). Operations execute with the current user's session - users without these permissions cannot make changes even through the agent.

**Slack Integration: ✅ Secure** - When used in Slack channels, Agentforce shows you a private draft response first. You review it, then decide whether to share it publicly. This prevents accidental exposure of sensitive data.

### Optional: Data Cloud Setup

The **Search Data Library** action searches company documents using Data Cloud. The scratch org creation script will prompt you to upload a sample PDF into a Data Library — the same file that's already attached to the demo Opportunity for file grounding.

> **Note:** Your DevHub needs "Create Data Cloud Scratch Org" permissions. If you don't have this, [open a Partner Community case](https://partners.salesforce.com/) to request it.

Without completing the Data Library setup, the action deploys fine but returns no results.

### How can I make this my own?

1. Clone this repo
2. Replace `aquiva_os` namespace with your own (or remove it)
3. Create a scratch org: `./scripts/create-scratch-org.sh`
4. Make your changes
5. Create a 2GP package in your dev hub (one-time setup)
6. Create package versions: `./scripts/create-package-version.sh`
