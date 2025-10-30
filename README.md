## <img src="resources/logo.png" width="50"/> My Org Butler

My Org Butler is a showcase for building Agentforce solutions that help Salesforce users with their daily work. Using natural language, it answers questions about data, metadata, and configuration, and can perform tasks like creating records, making configuration changes, or notifying other people.

> ⚠️ **Looking for the custom OpenAI version?**
> 
> This is the **Agentforce-only version** that's simple to set up and use. If you're looking for the version that uses OpenAI with custom UI components, please check out the [`openai-agentforce-hybrid`](../../tree/openai-agentforce-hybrid) branch.


### Show me a demo

[![Agentforce Demo](http://img.youtube.com/vi/_pz1rgWpDXU/hqdefault.jpg)](https://youtu.be/LuLv77KKRIo?si=-ya1wjyksBH2jZbG&t=656 "Agentforce Version")


Find all of Aquiva's My Org Butler related video demos at this [YouTube playlist](https://youtube.com/playlist?list=PL9OHq276T12G1Ngw5m05KZyY5jwF5qMLD&si=rmKXPGRYhw4Bxgs9).

---

### Getting started

Follow these steps to get My Org Butler running in your org:

1. **Install Prerequisite** - Install the [latest version](https://login.salesforce.com/packaging/installPackage.apexp?p0=04tVI000000L3ZBYA0) of the [App Foundations](https://github.com/aquivalabs/app-foundations) package (prerequisite)

2. **Install My Org Butler 2.19** - [Production](https://login.salesforce.com/packaging/installPackage.apexp?p0=) or [Sandbox](https://test.salesforce.com/packaging/installPackage.apexp?p0=)

3. **Enable Agentforce** in your org (if not already enabled)

4. **Create an Agent from Template** - After installing the package, create a new agent from the `My Org Butler` template. See [Salesforce Help](https://help.salesforce.com/s/articleView?id=ai.agent_employee_agent_setup.htm&type=5) for instructions.

5. **Turn on Optional Features** (choose which capabilities you want to enable):

   **Turn on GitHub Integration:**
   1. Get a [GitHub Personal Access Token](https://github.com/settings/tokens)
   2. Go to **Setup → Named Credentials → `GitHubApi`**
   3. Click on the linked External Credential `GitHubApi`
   4. Create a New Named Principal with parameter name `ApiKey` 
   5. Enter your GitHub token as the value

   **Turn on Web Search:**
   1. Get a [free Tavily API key](https://tavily.com/)
   2. Go to **Setup → Named Credentials → `TavilyApi`**
   3. Click on the linked External Credential `TavilyApi`  
   4. Create a New Named Principal with parameter name `ApiKey`
   5. Enter your Tavily API key as the value

   **Turn on External Knowledge Search:**
   1. Create a free account at [Vectorize.io](https://platform.vectorize.io/)
   2. Build a RAG pipeline with your company documents (wikis, documentation, etc.)
   3. Note your **Organization ID** and **Pipeline ID** from the Vectorize dashboard
   4. Get your **API token** from the Vectorize backend
   5. Go to **Setup → Named Credentials → `VectorizeApi`**
   6. Click on the linked External Credential `VectorizeApi`
   7. Create a New Named Principal with parameter name `Token`
   8. Enter your Vectorize API token as the value
   9. Go to **Setup → Custom Settings → Custom Setting → Manage**
   10. Create a new record with Name: `VectorizeOrgId`, Value: your Organization ID
   11. Create another record with Name: `VectorizePipelineId`, Value: your Pipeline ID

That's it! The Butler will be available in your Agentforce sidebar and can now search your external knowledge sources.

### What it does

Built entirely on Agentforce with 9 functions and 5 plugins. The functions handle Salesforce-specific tasks like querying data, calling APIs, and managing metadata. Agentforce provides the AI reasoning and conversation management.

**Data & Records:**
- Answer questions about your org's data, metadata and settings
- Create and update records (delete not supported)
- Query complex data relationships and generate reports

**Metadata & Configuration:**
- Explain Salesforce metadata components and configurations
- Create and modify Apex classes, Flows, and custom objects
- Analyze validation rules, custom fields, and object relationships
- Generate PlantUML diagrams for data models and processes

**GitHub Integration:**
- Manage GitHub repositories, issues, and pull requests
- View commit history and compare code changes
- Search repositories and track development progress

**Advanced Capabilities:**
- Search the web for additional information using Tavily API
- Search your company's external knowledge base using Vectorize (wikis, docs, etc.)
- Create visual diagrams and documentation


### Development

Want to customize or extend the Butler?

1. Clone this repo
2. Replace `aquiva_os` namespace with your own (or remove it)
3. Create a scratch org: `./scripts/create-scratch-org.sh`
4. Make your changes
5. Create a package and versions: `./scripts/create-package.sh`
