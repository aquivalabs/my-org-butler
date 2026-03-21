## <img src="resources/logo.png" width="50"/> My Org Butler [`v2.32.0`](https://github.com/aquivalabs/my-org-butler/releases/tag/v2.32.0)

My Org Butler is a showcase for building Agentforce solutions that help Salesforce users with their daily work. It started in early 2024 on the [OpenAI Assistants API with a custom LWC frontend](../../tree/openai-agentforce-hybrid), then moved to pure Agentforce when it became powerful enough. Using natural language, it answers questions about data, metadata, and configuration, and can perform tasks like creating records, making configuration changes, or notifying other people.


### Show me a demo

[![Agentforce Demo](http://img.youtube.com/vi/_pz1rgWpDXU/hqdefault.jpg)](https://youtu.be/LuLv77KKRIo?si=-ya1wjyksBH2jZbG&t=656 "Agentforce Version")


Find all of Aquiva's My Org Butler related video demos at this [YouTube playlist](https://youtube.com/playlist?list=PL9OHq276T12G1Ngw5m05KZyY5jwF5qMLD&si=rmKXPGRYhw4Bxgs9).

---

### How to install

1. **Install Prerequisite** - Install the [latest version](https://login.salesforce.com/packaging/installPackage.apexp?p0=04tVI000000L3ZBYA0) of the [App Foundations](https://github.com/aquivalabs/app-foundations) package (prerequisite)
2. **Install My Org Butler** - Grab the latest package version ID from [sfdx-project.json](sfdx-project.json) and install via [Production](https://login.salesforce.com/packaging/installPackage.apexp?p0=) or [Sandbox](https://test.salesforce.com/packaging/installPackage.apexp?p0=)
3. **Enable Agentforce** in your org (if not already enabled)
4. **Create an Agent from Template** - Create a new agent from the My Org Butler template with API name `MyOrgButler`. See [Salesforce Help](https://help.salesforce.com/s/articleView?id=ai.agent_employee_agent_setup.htm&type=5) for instructions.
5. **Turn on Optional Features** (choose which capabilities you want to enable):

   **Turn on Web Search:**
   1. Get a [free Tavily API key](https://tavily.com/)
   2. Go to **Setup → Named Credentials → `TavilyApi`**
   3. Click on the linked External Credential `TavilyApi`  
   4. Create a New Named Principal with parameter name `ApiKey`
   5. Enter your Tavily API key as the value

That's it! The Butler will be available in your Agentforce sidebar.

### What can the Butler do?

Built entirely on Agentforce with [**1 topic**](force-app/main/default/genAiPlugins/) and [**14 actions**](force-app/main/default/genAiFunctions/). Agentforce handles AI reasoning and conversation management. The actions handle the Salesforce-specific work:

- Query data, metadata, and settings using [natural language SOQL](force-app/main/default/genAiFunctions/QueryRecordsWithSoql/)
- Create and update records via the [REST API](force-app/main/default/genAiFunctions/CallRestApi/)
- Read and modify code and configuration via the [Tooling API](force-app/main/default/genAiFunctions/CallToolingApi/) and [Metadata API](force-app/main/default/genAiFunctions/CallMetadataApi/)
- Generate [PlantUML diagrams](force-app/main/default/genAiFunctions/CreatePlantUmlUrl/) for data models and processes
- [Search the web](force-app/main/default/genAiFunctions/SearchWeb/)
- [Notify](force-app/main/default/genAiFunctions/NotifyUser/) people and [delegate tasks](force-app/main/default/genAiFunctions/RunMyOrgButler/) to a headless sub-agent

### Is it safe?

**Salesforce Data: ✅ Secure** - All queries use `USER_MODE` and `with sharing`. Users only see records they have permission to access. Field-level security, object permissions, and sharing rules are fully enforced.

**Metadata & Tooling API: ✅ Permission-Gated** - Create, update, and delete operations on metadata/code require specific user permissions ("View All Data" for Tooling API, "Modify Metadata" or "Author Apex" for Metadata API). Operations execute with the current user's session - users without these permissions cannot make changes even through the agent.

**Slack Integration: ✅ Secure** - When used in Slack channels, Agentforce shows you a private draft response first. You review it, then decide whether to share it publicly. This prevents accidental exposure of sensitive data.

### How can I make this my own?

1. Clone this repo
2. Replace `aquiva_os` namespace with your own (or remove it)
3. Create a scratch org: `./scripts/create-scratch-org.sh`
4. Make your changes
5. Create a 2GP package in your dev hub (one-time setup)
6. Create package versions: `./scripts/create-package-version.sh`
