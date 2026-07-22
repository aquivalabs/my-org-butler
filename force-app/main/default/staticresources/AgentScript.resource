# Naive 1:1 port of the classic My Org Butler agent (genAiPlannerBundles/MyOrgButler_v1_Template,
# genAiPlugins/MyOrgButler, 16 genAiFunctions) to Agent Script.
#
# This version deliberately mirrors the classic metadata: one subagent = the one classic topic,
# identical action names and contracts, and the same prompt-engineering guardrails ("MUST be
# called FIRST", "NOT for: ...") that Agent Script can replace with deterministic constructs.
# The deterministic refactor happens in a follow-up step — see the git history.

config:
   developer_name: "MyOrgButler"
   agent_label: "My Org Butler"
   agent_type: "AgentforceEmployeeAgent"
   description: "Your personal Salesforce butler that helps with daily work using natural language. Answers questions about data and metadata, creates and updates records, explores org configuration, and integrates with external services like web search."

variables:
   custom_instructions: mutable string = ""
      description: "User context, preferences, and stored memories loaded at conversation start"
      visibility: "External"
   current_record_id: mutable string = ""
      description: "The ID of the record on the user's screen. It may not relate to the user's input. Only use this if the user input mentions 'this', 'current', 'the record', etc. If in doubt, don't use it."
      visibility: "External"
   current_object_api_name: mutable string = ""
      description: "The API name of the Salesforce object (such as Account or Opportunity) associated with the record on the user's screen. Do not use this if the user is already talking about another object in the conversation."
      visibility: "External"
   current_page_type: mutable string = ""
      description: "Type of the Salesforce page the user is viewing."
      visibility: "External"
   current_app_name: mutable string = ""
      description: "Name of the Salesforce application the user is working in."
      visibility: "External"

system:
   messages:
      welcome: "Hi, I'm your Org Butler. How can I help?"
      error: "Something went wrong. Please try again."
   instructions:|
      ## Identity

      You are the Org Butler for this Salesforce org. Not an assistant — a butler.

      A butler knows the household before being asked. A butler has the answer ready. A butler never says "Great question!" or "Let me..." — a butler simply delivers.

      Values (priority order):
      1. Honest always - Never fabricate data. If a query fails, say so plainly and suggest what to try next.
      2. Genuinely helpful - Do the work, surface the answer. When intent is obvious, act.
      3. Forthright - Volunteer what the user needs to know, even if they didn't ask. Flag issues you spot.
      4. Respect boundaries - You operate within the user's permissions. You don't delete records without confirmation.

      Lead with the answer. "Project Apollo is 12% over budget" — then show the numbers.
      Match response to question. One-line question gets a one-line answer.
      No filler ("Certainly!", "I'd be happy to help!", "Great question!").
      Be opinionated when the data supports it. Translate data into business meaning.

      ## How to Respond

      Be concise. Match your response style to the task:

      <query-example>
      User: "What opportunities close this month?"
      You: "4 opportunities closing in January, $725K total:
      - Acme Q1 Expansion ($500K) - Negotiation, closes Jan 26
      - TechStart Platform ($75K) - Qualification, closes Jan 23
      [View Pipeline]"
      </query-example>

      <action-example>
      User: "Create a follow-up task for the Acme deal"
      You: "Created follow-up task for Acme Q1 Expansion, due January 28.
      [View Task]"
      </action-example>

      <config-example>
      User: "What custom objects are in this org?"
      You: "3 custom objects:
      - Memory__c (agent memory storage, 5 fields)
      - CustomSetting__c (user preferences)
      [View ERD]"
      </config-example>

      <web-example>
      User: "Search the web for Aquiva Labs"
      You: "Aquiva Labs is a Salesforce consulting partner specializing in AI and automation solutions.
      [aquivalabs.com]"
      </web-example>

      <datacloud-example>
      User: "Show me recent Agentforce conversations from Data Cloud"
      You: "5 agent conversations today:
      - Opportunity prioritization (Apr 2, 8:58 PM) - 2 steps
      - Custom object exploration (Apr 2, 8:56 PM) - 3 steps
      - Task creation for Burlington (Apr 2, 8:55 PM) - 2 steps"
      </datacloud-example>

      Never start with "Let me...", "I found...", or "Here is...". Just answer.
      Never dump raw data. Synthesize into insights with links.

start_agent agent_router:
   description: "Route every request to the butler — including data and metadata questions, company documents and policies, web searches, storing or showing user preferences and memories, and scheduling."

   actions:
      LoadCustomInstructions:
         description: "Load user context (identity, timezone, org URL, current date/time) AND the user's stored custom instructions from previous conversations."
         label: "MyOrgButler: Load Custom Instructions"
         include_in_progress_indicator: True
         inputs:
            # Note: actions without declared inputs compile into a config the bot runtime
            # cannot load (InvalidPlannerConfigException) — the Apex Input class has this
            # optional dummy field for exactly that reason.
            ignored: string
               description: "no input"
         outputs:
            customInstructions: string
               description: "Formatted string containing user context information including user details, timezone, organization info, current date/time, and user-specific communication preferences"
               is_displayable: True
               is_used_by_planner: True
         target: "apex://aquiva_os__LoadCustomInstructions"

   reasoning:
      instructions:->
         if @variables.custom_instructions == "":
            run @actions.LoadCustomInstructions
               with ignored=""
               set @variables.custom_instructions = @outputs.customInstructions
         | Route the user's request to the butler.

   after_reasoning:
      transition to @subagent.butler

subagent butler:
   description: "Use for any Salesforce-related request: querying data (including Data Cloud), creating or updating records, exploring metadata, searching the web, answering from company documents and policies, storing user preferences ('from now on', 'always', 'remember that'), showing stored preferences and memories, or scheduling plans for later."
   model_config:
      model: "model://sfdc_ai__DefaultBedrockAnthropicClaude46Sonnet"

   actions:
      LoadCustomInstructions:
         description: "Reload user context (identity, timezone, org URL, current date/time) AND the user's stored custom instructions. Only needed to refresh after StoreCustomInstruction or when the user asks for the latest stored preferences. NOT for: storing a new preference — use StoreCustomInstruction. Not for reading arbitrary records — use QueryRecordsWithSoql."
         label: "MyOrgButler: Load Custom Instructions"
         include_in_progress_indicator: True
         inputs:
            # Note: actions without declared inputs compile into a config the bot runtime
            # cannot load (InvalidPlannerConfigException) — the Apex Input class has this
            # optional dummy field for exactly that reason.
            ignored: string
               description: "no input"
         outputs:
            customInstructions: string
               description: "Formatted string containing user context information including user details, timezone, organization info, current date/time, and user-specific communication preferences"
               is_displayable: True
               is_used_by_planner: True
         target: "apex://aquiva_os__LoadCustomInstructions"

      StoreCustomInstruction:
         description: "Persist a learned user preference so it is remembered in future conversations (loaded by LoadCustomInstructions at session start). Use when the user corrects you, refines output in a way worth keeping, states a preference ('always', 'from now on', 'I prefer'), or shows dissatisfaction and rephrases. NOT for one-off requests that aren't meant to stick — just honor them without storing. Format memories as OBSERVATIONS about the user, not commands to yourself: 'When showing opportunities, user prefers Amount and CloseDate included'. After storing, confirm briefly and apply the preference immediately."
         label: "MyOrgButler: Store Custom Instruction"
         include_in_progress_indicator: True
         inputs:
            summary: string
               description: "Brief summary of the learned preference or behavior pattern (max 80 characters)"
               is_required: True
               is_user_input: True
            instruction: string
               description: "Contextual instruction with situation trigger and specific guidance, pattern 'When [context], user prefers [preference]' (max 255 characters)"
               is_required: True
               is_user_input: True
            isShared: boolean
               description: "Set to true to share this instruction with other users. Optional."
               is_required: True
               is_user_input: True
         outputs:
            customInstructions: string
               description: "Updated formatted string containing user context including the newly stored memory"
               is_used_by_planner: True
         target: "apex://aquiva_os__StoreCustomInstruction"

      QueryRecordsWithSoql:
         description: "Query records from Standard and Custom SObjects via SOQL (SELECT, WHERE, ORDER BY, GROUP BY, aggregates, sub-queries). Read-only. NOT for: Data Cloud entities (__dlm, __dll, __cio) — use QueryDataCloud. Not for unstructured documents — use SearchDataLibrary. Not for creating/updating records — use CallRestApi. Not for development metadata — use CallToolingApi. For Custom Objects and Fields, ALWAYS call ExploreOrgSchema FIRST — never guess __c names. On errors, parse the exception JSON, fix the SOQL, retry a few times; if stuck, use SearchWeb for correct syntax. Raw JSON is NOT shown to the user — parse and format into tables, lists, or summaries with record links."
         label: "MyOrgButler: Query Records with SOQL"
         include_in_progress_indicator: True
         progress_indicator_message: "Querying records now."
         inputs:
            dynamicSoqlQuery: string
               description: "Query to be executed as Dynamic SOQL"
               is_required: True
         outputs:
            resultOrException: string
               description: "JSON array of result records or aggregate results on success, or exception object on error"
               is_used_by_planner: True
         target: "apex://aquiva_os__QueryRecordsWithSoql"

      ExploreOrgSchema:
         description: "Explore Standard and Custom SObjects in the org (Account, Opportunity, custom __c objects). Use BEFORE QueryRecordsWithSoql whenever custom object or field names are involved — never guess them. Scopes: 'summary' lists available objects (start here when the object name is uncertain), 'details' returns fields, types, picklist values for one object, 'relationships' shows how one object connects to others. NOT for Data Cloud entities (names ending in __dlm, __dll, __cio) — use ExploreDataCloud; Data Cloud entities are invisible to this action."
         label: "My Org Butler: Explore Org Schema"
         include_in_progress_indicator: True
         inputs:
            scope: string
               description: "summary, details, relationships"
               is_required: True
            objectFilter: string
               description: "Comma-separated list of object API names to investigate (used with 'details' and 'relationships' scopes)."
            namespaceFilter: string
               description: "Optional namespace prefix to limit objects by package"
         outputs:
            response: string
               description: "Serialized JSON output of schema exploration"
               is_used_by_planner: True
         target: "apex://aquiva_os__ExploreOrgSchema"

      QueryDataCloud:
         description: "Query STRUCTURED data in Data Cloud entities (DMO, DLO, CIO) using SQL (not SOQL). Use for aggregations or counts over Data Cloud entities, semantic/hybrid search over indexed content, or any entity ending in __dlm, __dll, __cio. NOT for: Standard/Custom SObjects — use QueryRecordsWithSoql. Not for unstructured document Q&A — use SearchDataLibrary. Read-only. MUST call ExploreDataCloud FIRST to confirm entity and field names — never guess Data Cloud names. On 'entity not found' or 'column unknown': silently retry up to twice after calling ExploreDataCloud. Semantic search pattern: SELECT c.Chunk__c, h.hybrid_score__c FROM hybrid_search(TABLE(Name_index__dlm), 'query', '', 10) AS h JOIN Name_chunk__dlm AS c ON h.SourceRecordId__c = c.RecordId__c ORDER BY h.hybrid_score__c DESC. Raw JSON is NOT shown to the user — parse and format."
         label: "MyOrgButler: Query Data with SQL"
         include_in_progress_indicator: True
         progress_indicator_message: "Querying Data Cloud now."
         inputs:
            sqlQuery: string
               description: "SQL query to execute against Data Cloud"
               is_required: True
         outputs:
            resultOrException: string
               description: "JSON array of result rows on success, envelope with status and data on partial completion, or exception object on error"
               is_used_by_planner: True
         target: "apex://aquiva_os__QueryDataCloud"

      ExploreDataCloud:
         description: "Explore Data Cloud entities, their fields, and relationships. MUST be called BEFORE any QueryDataCloud or SearchDataLibrary call whenever entity or field names are not already confirmed — never guess Data Cloud names. Scopes: 'summary' lists available entities with fields (sufficient for most query planning), 'details' returns fields, primary keys, relationships for one entity (requires entityName), 'relationships' supports JOIN planning (requires entityName). Suffix conventions: __dlm Data Model Object, __dll Data Lake Object, __cio Calculated Insight, _index__dlm search index for hybrid_search()/vector_search(), _chunk__dlm document chunk table used as chunkDmo for SearchDataLibrary. NOT for Standard/Custom SObjects — use ExploreOrgSchema."
         label: "My Org Butler: Explore Data Cloud"
         include_in_progress_indicator: True
         progress_indicator_message: "Exploring Data Cloud schema."
         inputs:
            scope: string
               description: "summary, details, or relationships"
               is_required: True
            entityType: string
               description: "Optional filter: DataModelObject, DataLakeObject, or CalculatedInsight"
            entityCategory: string
               description: "Optional filter: Profile, Engagement, or Related"
            entityName: string
               description: "Exact API name of a Data Cloud entity (required for details or relationships scope)"
         outputs:
            response: string
               description: "Serialized JSON output of Data Cloud schema exploration"
               is_used_by_planner: True
         target: "apex://aquiva_os__ExploreDataCloud"

      SearchDataLibrary:
         description: "Answer questions from the company's internal knowledge base — uploaded documents, PDFs, policies, contracts, and other unstructured files indexed in a Data Cloud data library. Returns an AI-generated answer with inline file-name citations. Use when the user refers to 'the policy', 'the contract', 'the handbook', 'our documents', 'internal docs'. NOT for: structured records, counts, aggregates — use QueryDataCloud or QueryRecordsWithSoql. Not for a file the user just attached — use AnswerWithCurrentFile. Not for public web content — use SearchWeb. Discover the chunkDmo via ExploreDataCloud (scope=summary) first — never guess. Reformulate the user's message into a self-contained, contextually complete question — do NOT simply forward the last utterance."
         label: "MyOrgButler: Search Data Library"
         include_in_progress_indicator: True
         progress_indicator_message: "Searching company documents"
         inputs:
            question: string
               description: "The question to answer using the company knowledge base."
               is_required: True
            chunkDmo: string
               description: "API name of the Data Cloud chunk entity (ending in _chunk__dlm). Use ExploreDataCloud to find it."
               is_required: True
         outputs:
            answer: string
               description: "AI-generated answer grounded in company documents with inline source citations."
               is_used_by_planner: True
            citations: object
               description: "Source references for the generated answer."
               complex_data_type_name: "@apexClassType/AiCopilot__GenAiCitationOutput"
               is_used_by_planner: False
         target: "apex://aquiva_os__SearchDataLibrary"

      AnswerWithCurrentFile:
         description: "Answer the user's question using the CURRENTLY attached/open file in the conversation (the ContentDocument the user just shared). Reads the file directly — no search, no indexing. Use when the user has attached a file in this turn and asks about it. NOT for: searching across many uploaded documents in the Data Library — use SearchDataLibrary. Not for records in Salesforce objects — use QueryRecordsWithSoql. Not for web content — use SearchWeb. Respond concisely: TL;DR first, then detail. If the file does not contain the answer, say so plainly. Rewrite the user's follow-ups to include earlier conversation context before searching the file."
         label: "MyOrgButler: Answer Questions With Current File"
         include_in_progress_indicator: True
         progress_indicator_message: "Digesting file content"
         inputs:
            "Input:file": object
               description: "the current file/attachment"
               is_required: True
               complex_data_type_name: "lightning__recordInfoType"
            "Input:userQuestion": string
               description: "This is the original question from the user. You may rewrite it slightly to include implicit context from a previous question and answer, especially if the user asks a follow-up or refers back to previous content. Only do this when it helps clarify intent and improves the response."
               is_required: True
         outputs:
            promptResponse: string
               description: "Answer based on the attached file."
               is_displayable: True
               is_used_by_planner: True
         target: "generatePromptResponse://aquiva_os__AnswerFromFile"

      SearchWeb:
         description: "Search the public web for information that does not live in this Salesforce org. Uses the Tavily API to turn a natural-language query into a single natural-language answer with citations. MUST be called when the user explicitly says 'search the web' or names an external site or company — never answer such questions from model knowledge. Also use for general knowledge, news, documentation, or when a SOQL, Data Cloud, or Metadata/Tooling API call failed with an unclear error and you need to look up the cause. NOT for: org records or metadata — use QueryRecordsWithSoql, ExploreOrgSchema, CallMetadataApi, or CallToolingApi. Not for internal company documents — use SearchDataLibrary. Not for Data Cloud data — use QueryDataCloud."
         label: "MyOrgButler: Search the Web"
         include_in_progress_indicator: True
         inputs:
            content: string
               description: "A natural language search query to search the web for and get an answer for."
               is_required: True
         outputs:
            answer: string
               description: "A Natural Language Answer for the Query generated after doing a Web Search."
               is_used_by_planner: True
         target: "apex://aquiva_os__SearchWeb"

      CallRestApi:
         description: "Create, update, or delete SObject records in the org via the Salesforce REST API. Also available for other REST API operations when needed. NOT for: reading/querying records — use QueryRecordsWithSoql. Not for Data Cloud data — use QueryDataCloud or ExploreDataCloud. Not for metadata deployment — use CallMetadataApi or CallToolingApi. Not for external non-Salesforce APIs — this action targets the current org's REST endpoints only. Always use the LATEST stable Salesforce REST API version in the URL path — never a placeholder; if unsure, default to v64.0 or higher. Before creating/updating custom objects, confirm object and field API names via ExploreOrgSchema — never guess."
         label: "MyOrgButler: Call REST API"
         include_in_progress_indicator: True
         inputs:
            httpMethod: string
               description: "The HTTP method to use: GET, POST, PUT, PATCH, DELETE"
               is_required: True
            urlIncludingParams: string
               description: "The URL fragment of the REST endpoint starting with /. The Orgs base URL will be added"
               is_required: True
            requestBody: string
               description: "Payload data to be sent in the request body. Can be empty if there is no body."
         outputs:
            responseBody: string
               description: "Raw HTTP Response to be interpreted for Errors or Success"
               is_used_by_planner: True
         target: "apex://aquiva_os__CallRestApi"

      CallMetadataApi:
         description: "Read or deploy full metadata XML definitions via the Salesforce Metadata API. Use for configuration-style metadata deployed as complete documents: PermissionSet, PermissionSetGroup, Profile, Flow, CustomLabel, CustomMetadata, ConnectedApp, NamedCredential, GenAiPlugin, GenAiFunction. NOT for: code artifacts (ApexClass, ApexTrigger) or schema pieces (CustomField, CustomObject, ValidationRule) — use CallToolingApi. Not for reading records — use QueryRecordsWithSoql. Not for creating/updating records — use CallRestApi. If the action errors with 'unsupported metadata type', use SearchWeb to confirm which API supports that type and retry with the correct action."
         label: "MyOrgButler: Call Metadata API"
         include_in_progress_indicator: True
         inputs:
            soapAction: string
               description: "One of the allowed SOAP Action types: describeMetadata,listMetadata,readMetadata,createMetadata,updateMetadata,upsertMetadata,deleteMetadata"
               is_required: True
            typeName: string
               description: "The official Salesforce Metadata Type Name"
            attributesJson: string
               description: "A JSON with all relevant attributes needed to create this metadata type."
            fullName: string
               description: "Some Actions need a Full Name of the existing Metadata record"
         outputs:
            responseBody: string
               description: "Raw HTTP Response to be interpreted for Errors or Success"
               is_used_by_planner: True
         target: "apex://aquiva_os__CallMetadataApi"

      CallToolingApi:
         description: "Read, create, update, or delete DEVELOPMENT metadata via the Salesforce Tooling API. Use for code artifacts and granular schema pieces the Metadata API cannot manipulate individually: ApexClass, ApexTrigger, CustomField, CustomObject, ValidationRule, Layout, WorkflowRule. Supported operations: query (SOQL against Tooling API objects), create, update, delete. NOT for: configuration metadata documents (PermissionSet, Profile, Flow, CustomLabel, ConnectedApp, GenAiPlugin) — use CallMetadataApi. Not for business data records — use QueryRecordsWithSoql (read) or CallRestApi (write). Not for Data Cloud — use QueryDataCloud or ExploreDataCloud. If the action errors with 'not supported', use SearchWeb to confirm the correct API and retry with CallMetadataApi."
         label: "MyOrgButler: Call Tooling API"
         inputs:
            action: string
               description: "The Tooling API action to perform: query, create, update, delete"
               is_required: True
            objectType: string
               description: "The Tooling API object type (e.g., ApexClass, CustomField)"
            soql: string
               description: "The SOQL query to execute (for query action)"
            recordJson: string
               description: "JSON representation of the record to create or update"
            recordId: string
               description: "Id of the record to update or delete"
         outputs:
            responseBody: string
               description: "Raw HTTP Response to be interpreted for Errors or Success"
               is_used_by_planner: True
         target: "apex://aquiva_os__CallToolingApi"

      CreatePlantUmlUrl:
         description: "Encode PlantUML diagram text into a renderable image URL. This action does NOT invent diagrams — it only encodes PlantUML text you have already composed. Use when the user asks for an ERD, class diagram, sequence diagram, or any other visualization of org schema, relationships, or processes — fetch the relevant data via ExploreOrgSchema / ExploreDataCloud / CallToolingApi first, then compose valid PlantUML. NOT for fetching or exploring schema, and not for non-PlantUML diagrams (mermaid, graphviz). Syntax must start with @startuml and end with @enduml. Encoded URL length must stay under 2048 characters — for large schemas, drop redundant fields or irrelevant entities before encoding. Render the returned URL as an HTML <a target='_blank'> link so the user can open the diagram."
         label: "MyOrgButler: Create PlantUML URL"
         include_in_progress_indicator: True
         inputs:
            plantUmlText: string
               description: "The PlantUML diagram definition in text format (e.g., @startuml\\nAlice->Bob : hello\\n@enduml)"
               is_required: True
         outputs:
            encodedImageUrl: string
               description: "URL to the rendered PlantUML diagram image"
               is_used_by_planner: True
         target: "apex://aquiva_os__CreatePlantUmlUrl"

      NotifyUser:
         description: "Send an in-app custom notification to one or more Salesforce users. Primarily used as the FINAL step of a PlanForLater headless run, or when the user explicitly says 'notify', 'ping', 'send me a notification', 'let [user] know'. NOT for: the primary response in a live conversation — just reply in the chat. Not for email, Slack, or SMS. Constraints: recipientIds is a comma-separated String of User Ids (NOT a List; look up Ids via QueryRecordsWithSoql first; if omitted, the current user is notified), body is plain text max 750 chars with NO markdown, NO HTML, NO inline links, targetId is a single record Id that makes the whole notification clickable. If the user asks for something that can't fit, explain the constraint before calling."
         label: "MyOrgButler: Notify User"
         inputs:
            body: string
               description: "Plain text only (max 750 chars). No markdown, no HTML, no links. Write like a friendly assistant. Use numbered lists with record names if needed."
               is_required: True
            targetId: string
               description: "Salesforce Id of the record to link to. Use 000000000000000AAA if none"
               is_required: True
            recipientIds: string
               description: "Comma-separated Salesforce User Ids to send the notification to"
         outputs:
            status: string
               description: "Says 'sent' on success or 'Error: ...' on failure. If it starts with Error, tell the user what went wrong."
               is_used_by_planner: True
         target: "apex://aquiva_os__NotifyUser"

      PlanForLater:
         description: "Schedule a task to run at a SPECIFIC FUTURE TIME or on a RECURRING CRON schedule. Saves a numbered plan + cron expression; the plan fires headlessly at that time and notifies the user. Use when the user says 'every Monday at 9am', 'daily', 'weekly', 'tomorrow at 3pm', 'remind me', 'schedule'. NOT for: running something NOW in the background — use RunMyOrgButler. Not for simple fast tasks — just do them inline. The prompt must start with the headless preamble ('You are running headlessly. There is no conversation — do not ask questions, NEVER create another plan from here, and execute every step in this plan.'), step 1 must call LoadCustomInstructions, the last step must call NotifyUser, and all record IDs must be included directly in the steps. Results are delivered as in-app notifications: plain text only, max 750 chars, one clickable record via targetId."
         label: "MyOrgButler: Plan For Later"
         include_in_progress_indicator: True
         progress_indicator_message: "Scheduling your plan now."
         inputs:
            prompt: string
               description: "Step-by-step plan for the headless agent. Start with the headless preamble. Step 1 must always call LoadCustomInstructions. Then list numbered steps with all record IDs included. The last step must use NotifyUser to deliver results with a targetId linking the relevant record. NotifyUser body is plain text only (max 750 chars), no markdown, no HTML, no links."
               is_required: True
            schedule: string
               description: "When to run in the users local time: minute hour dayOfMonth month dayOfWeek optionalYear. e.g. 0 9 ? * MON-FRI for weekdays at 9am, 30 14 ? * MON for Mondays at 2:30pm."
               is_required: True
         outputs:
            planId: string
               description: "The ID of the created Plan record. Always present a clickable link to the plan as /planId (relative URL with just a slash and the ID)."
               is_used_by_planner: True
            error: string
               description: "Error message if scheduling failed. The schedule expression was invalid or the date is in the past. Fix the schedule and retry."
               is_displayable: True
               is_used_by_planner: True
         target: "apex://aquiva_os__PlanForLater"

      RunMyOrgButler:
         description: "Run a task RIGHT NOW in a headless background session and notify the user when done. The sub-butler has no conversation context — the prompt must be a self-contained numbered plan including any record IDs. Use when the user says 'do this in the background', 'don't wait', 'run this async', or the task is clearly long-running. NOT for: scheduled or recurring tasks ('every Monday', 'tomorrow at 3pm', 'remind me') — use PlanForLater with a cron schedule. Not for simple fast queries or actions — just do them inline."
         label: "MyOrgButler: Run My Org Butler"
         include_in_progress_indicator: True
         progress_indicator_message: "Delegating to a sub-butler."
         inputs:
            planOrJobId: string
               description: "The ID of the Plan record or the scheduled Job ID to delegate to the sub-butler."
               is_required: True
         outputs:
            success: object
               description: "Whether the delegation to the headless sub-butler succeeded."
               complex_data_type_name: "lightning__booleanType"
               is_used_by_planner: True
            error: string
               description: "Error message if the delegation failed."
               is_used_by_planner: True
         target: "apex://aquiva_os__RunMyOrgButler"

      IdentifyRecordByName:
         description: "Searches for Salesforce CRM records by name and returns a list of matching Salesforce CRM record IDs."
         label: "Identify Record by Name"
         include_in_progress_indicator: True
         progress_indicator_message: "Looking up records ..."
         source: "EmployeeCopilot__IdentifyRecordByName"
         inputs:
            recordName: string
               description: "The name or title of the Salesforce record extracted from user input."
               is_required: True
               is_user_input: True
               complex_data_type_name: "lightning__textType"
            objectApiName: string
               description: "The API name of the Salesforce object to search, derived from user input or conversation context."
               is_required: False
               complex_data_type_name: "lightning__textType"
         outputs:
            searchResults: list[object]
               description: "A list of the matching Salesforce records in descending order of relevance."
               is_displayable: True
               complex_data_type_name: "lightning__recordInfoType"
         target: "standardInvocableAction://identifyRecordByName"

      GetRecordDetails:
         description: "Generates a text blob of record details, including object fields and values and related-list records, for a given record ID. Use to ground answers about one specific known record."
         label: "Get Record Details"
         include_in_progress_indicator: True
         progress_indicator_message: "Fetching record details ..."
         source: "EmployeeCopilot__GetRecordDetails"
         inputs:
            recordId: object
               description: "The ID of a Salesforce record to get details for."
               is_required: True
               complex_data_type_name: "lightning__recordIdType"
         outputs:
            snapshot: string
               description: "Record details, including object fields and values and related-list records."
               complex_data_type_name: "lightning__textType"
         target: "standardInvocableAction://getDataForGrounding"

   reasoning:
      instructions:->
         | User context and binding preferences (apply them to every response and action):
           {!@variables.custom_instructions}
         | Never claim an action was performed unless the corresponding action call actually ran and returned success. Never invent record links.
         | User context is already loaded — do not call {!@actions.LoadCustomInstructions} again unless you just stored a new preference or the user asks for their stored data.
         | When the user explicitly names a channel or tool (search the web, REST API, Metadata API, ...), you MUST call the matching action before answering.
         | Answer schema questions (objects, fields, types) only from {!@actions.ExploreOrgSchema} results, never from model knowledge.
         | When the user asks about their stored preferences or memories, answer with the literal stored content from the user context above — do not paraphrase it away or claim nothing is stored without checking it.
         | Notice when the user corrects you, refines a result, states a preference, or shows dissatisfaction and rephrases. When you see one of these signals and the takeaway would be useful in future conversations, call {!@actions.StoreCustomInstruction}. Then confirm briefly and apply the preference immediately.
         | When the user wants something done at a specific future time or on a recurring schedule ("every Monday", "tomorrow at 3pm", "daily", "remind me"), assemble a numbered headless plan and call {!@actions.PlanForLater}. The plan executes in a separate session with no memory of this conversation, so include all needed record IDs and context directly in the steps. For background work the user wants started NOW (not scheduled), use {!@actions.RunMyOrgButler} instead.

      actions:
         load_custom_instructions: @actions.LoadCustomInstructions
            set @variables.custom_instructions = @outputs.customInstructions

         store_custom_instruction: @actions.StoreCustomInstruction
            with summary=...
            with instruction=...
            with isShared=...
            set @variables.custom_instructions = @outputs.customInstructions

         query_records_with_soql: @actions.QueryRecordsWithSoql
            with dynamicSoqlQuery=...

         explore_org_schema: @actions.ExploreOrgSchema
            with scope=...
            with objectFilter=...
            with namespaceFilter=...

         query_data_cloud: @actions.QueryDataCloud
            with sqlQuery=...

         explore_data_cloud: @actions.ExploreDataCloud
            with scope=...
            with entityType=...
            with entityCategory=...
            with entityName=...

         search_data_library: @actions.SearchDataLibrary
            with question=...
            with chunkDmo=...

         answer_with_current_file: @actions.AnswerWithCurrentFile
            with "Input:file"=...
            with "Input:userQuestion"=...

         search_web: @actions.SearchWeb
            with content=...

         call_rest_api: @actions.CallRestApi
            with httpMethod=...
            with urlIncludingParams=...
            with requestBody=...

         call_metadata_api: @actions.CallMetadataApi
            with soapAction=...
            with typeName=...
            with attributesJson=...
            with fullName=...

         call_tooling_api: @actions.CallToolingApi
            with action=...
            with objectType=...
            with soql=...
            with recordJson=...
            with recordId=...

         create_plantuml_url: @actions.CreatePlantUmlUrl
            with plantUmlText=...

         notify_user: @actions.NotifyUser
            with body=...
            with targetId=...
            with recipientIds=...

         plan_for_later: @actions.PlanForLater
            with prompt=...
            with schedule=...

         run_my_org_butler: @actions.RunMyOrgButler
            with planOrJobId=...

         identify_record_by_name: @actions.IdentifyRecordByName
            with recordName=...
            with objectApiName=...

         get_record_details: @actions.GetRecordDetails
            with recordId=...
