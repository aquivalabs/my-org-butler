## <img src="resources/logo.png" width="50"/> My Org Butler

My Org Butler is a showcase for building Agentforce solutions that help Salesforce users with their daily work. Using natural language, it answers questions about data, metadata, and configuration, and can perform tasks like creating records, making configuration changes, or notifying other people.

[![Agentforce Demo](http://img.youtube.com/vi/_pz1rgWpDXU/hqdefault.jpg)](https://youtu.be/_pz1rgWpDXU "Agentforce Version")


> ⚠️ **Looking for the custom OpenAI version?**
> 
> This is the **Agentforce-only version** that's simple to set up and use. If you're looking for the version that uses OpenAI with custom UI components, please check out the [`openai-agentforce-hybrid`](../../tree/openai-agentforce-hybrid) branch.

---

### Getting started

Follow these steps to get My Org Butler running in your org:

1. **Install Prerequisite** - Install the [latest version](https://login.salesforce.com/packaging/installPackage.apexp?p0=04tVI000000L3ZBYA0) of the [App Foundations](https://github.com/aquivalabs/app-foundations) package (prerequisite)

2. **Install My Org Butler v2.0** - [Production](https://login.salesforce.com/packaging/installPackage.apexp?p0=04tVI000000MgqDYAS) or [Sandbox](https://test.salesforce.com/packaging/installPackage.apexp?p0=04tVI000000MgqDYAS)

3. **Enable Agentforce** in your org (if not already enabled)

4. **Configure Named Credentials** (Optional - only if you want GitHub integration and web search):
   
   **For GitHub Integration:**
   - Get a [GitHub Personal Access Token](https://github.com/settings/tokens)
   - Go to Setup → Named Credentials → GitHubApi
   - Click on the linked External Credential "GitHubApi"
   - Create a New Named Principal with parameter name "ApiKey" 
   - Enter your GitHub token as the value

   **For Web Search:**
   - Get a [free Tavily API key](https://tavily.com/)
   - Go to Setup → Named Credentials → TavilyApi
   - Click on the linked External Credential "TavilyApi"  
   - Create a New Named Principal with parameter name "ApiKey"
   - Enter your Tavily API key as the value

That's it! The Butler will be available in your Agentforce sidebar.

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
- Create visual diagrams and documentation
- Respect user permissions and ask for clarification when needed
- Explain actions and self-correct errors

### Development

Want to customize or extend the Butler?

1. Clone this repo
2. Replace `aquiva_os` namespace with your own (or remove it)
3. Create a scratch org: `./scripts/create-scratch-org.sh`
4. Make your changes
5. Create a package: `./scripts/create-package.sh`