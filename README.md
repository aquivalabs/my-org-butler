# My Org Butler

Native Salesforce app that utilizes the Open AI Assistant API to provide a semi-autonomous agent in your org's utility bar. Using Natural language chat the Org Butler can answer the user's questions about org data and metatada, but also perform tasks on behalf of the user. Creating or modifying records, sending emails etc.

[![](http://img.youtube.com/vi/fcNnBZFvQHc/hqdefault.jpg)](https://youtu.be/fcNnBZFvQHc "")

The Org Butler is a small, native, self-contained Salesforce app with only one UI. A toolbar item that the org's admin can add to basically every screen in the org. The toolbar is collapsed most of the time but can be expanded by the user. It then reveals a simple, small chatbot with a predefined Open AI assistant. It plays the role of a friendly, helpful Butler that answers questions about org data (respecting the user's permissions) and metadata and performs specific jobs in the org (modify data, metadata). It uses a single Open AI Function configured to make arbitrary callouts to Salesforce APIs. Chat GPT knows a lot about those APIs, and the Assitant also contains a JSON Postman Collection that technically describes all those APIs.

The Assistant is prompted to make a work plan to fulfill the user's task and delegate Function calls back to the Salesforce app. The app then sends back the successful response from the API calls or the error states back to the assistant for corrections or summaries to the user.

Here is a short interaction diagram showing the participants and interactions in such a user-butler dialog:

![](/resources/plantuml.png)



### Highlight

- Write Rules in simple Natural language and group them in Rulesets.
- Run Analysis on Salesforce Files or Attachments
- Analysis Results will be justified by document quotes.
- Monitor the Accuracy of the AI using scheduled Regression Tests.
- Native Salesforce App with Custom Objects for Rules, Rulesets, Analyses etc.
- Uses Freemium Extractor API to extract text from documents (use your own API key)
- Uses Open AI API for text reasoning (use your own API key)
- Export & Import of Rulesets
- Comfortable Setup UI for Post-Install Steps
- Uses Custom Metadata Types to use other LLMs (was tested with Claude and Open Source Llama2)

### How do I use it?

1. Clone the repo
1. Create Scratch org
    1. Adjust the DEV_HUB_ALIAS in `/scripts/create-scratch.org.sh`
    1. Run it via `./scripts/create-scratch.org.sh`
1. Post-install steps
    1. Add your OpenAI API Key to a new Principal Parameter called `ApiKey` in `Setup > Named Credential > External Credential > OpenAiApi.ApiKey`
    1. Add the `External Credential > OpenAiApi` to the `Permission Set MyOrgButler` 
1. Create a Managed or Unlocked package from it using `/scripts/create-package.sh`