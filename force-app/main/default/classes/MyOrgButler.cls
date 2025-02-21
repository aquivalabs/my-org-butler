public with sharing class MyOrgButler implements Queueable, Database.AllowsCallouts {

    public static final String ASSISTANT_ID = assistantId();
    private static final Integer WAIT_TIME = 3000;
    private static final String CALLBACK_RUN_FINISHED = 'RUN_FINISHED';
    private static final Map<String, Tool> TOOLS = new Map<String, Tool>{ 
        'Get_User_Context' => new GetUserContextTool(),
        'Call_Salesforce_API' => new CallSalesforceApiTool(),
        'Notify_User' => new NotifyUserTool(),
        'Search_Web' => new SearchWebTool(),
        'Use_Metadata_API' => new UseMetadataApiTool(),
        'Use_Tooling_API' => new UseToolingApiTool(),
        'Explore_Org_Data_Model' => new ExploreOrgDataModelTool(),
        'Run_SOQL_Query' => new RunSoqlQueryTool()
    };

    @TestVisible
    private static AssistantCallback__e callback = null;

    private MyOrgButler__c settings;

    // CONSTRUCTOR

    public MyOrgButler() {
        settings = MyOrgButler__c.getInstance();

        if(settings.Id == null) {
            persistNewThread();
        }
    }

    // PUBLIC

    public String threadId() {
        return settings.ThreadId__c;
    }

    public void reset() {
        if(settings.ThreadId__c != null){
            Thread.remove(settings.ThreadId__c);
        }

        persistNewThread();
    }

    public List<Message> messages(String lastMessageId) {
        return Message.retrieve(settings.ThreadId__c, 
                                new Params()
                                        .order('asc')
                                        .afterRecord(lastMessageId))
                                        .data;
    }

    public Run.Steps steps(String runId) {
        return Run.steps(settings.ThreadId__c, runId, new Params());
    }

    public Run.Steps steps(String runId, String order) {
        return Run.steps(settings.ThreadId__c, runId, new Params().order(order));
    }

    public void respond(String question) {
        Message.create(settings.ThreadId__c, new Message(question));
        persistNewRun();
        enqueuePolling();
    }

    public void resume(String threadId) {
        Message.create(threadId, new Message('Thread resumed after wait. Please continue.'));
        persistNewRun();
        enqueuePolling();
    }

    public Message modify(Message existingMessage) {
        return Message.modify(settings.ThreadId__c, existingMessage);
    }

    public void execute(QueueableContext context) {
        new Sleep(WAIT_TIME);
        poll();
    }

    // PRIVATE

    private void persistNewThread() {
        Thread thread = Thread.create();
        settings.ThreadId__c = thread.id;
        settings.RunId__c = null;
        upsert as system settings;
    }

    private Run persistNewRun() {
        Run newRun = new Run(settings.ThreadId__c, ASSISTANT_ID);
        newRun = Run.create(settings.ThreadId__c, newRun);

        settings.RunId__c = newRun.id;
        update as system settings;
        return newRun;
    }

    private void enqueuePolling() {
        // Note: StackDepth can only be set in the initial enqueueJob
        if(System.isQueueable()) {
            System.enqueueJob(this);
        }
        else {
            AsyncOptions options = new AsyncOptions();
            options.MaximumQueueableStackDepth = 1000;
            System.enqueueJob(this, options);
        }
    }

    private void poll() {
        Run run = Run.retrieve(settings.ThreadId__c, settings.RunId__c);

        if(run.isPending()) {
            enqueuePolling();
        } 
        else if(run.requestsTool()) {
            runToolAndCallback(run);
            enqueuePolling();
        } 
        else if(run.isCompletedOrFailed()) {
            notifyUi(run);
        }
    }

    private void runToolAndCallback(Run run) {
        List<Run.ToolOutput> outputs = new List<Run.ToolOutput>();

        for(Run.ToolCall call : run.required_action.submit_tool_outputs.tool_calls) {
            Run.ToolOutput result = new Run.ToolOutput(call.id);

            if(!TOOLS.containsKey(call.function.name)) {
                result.output = 'ERROR: There is no such tool/action/function : ' + call.function.name;
            }

            try {
                Tool tool = TOOLS.get(call.function.name);
                tool.setThreadId(settings.ThreadId__c);
                result.output = tool.execute(call.function.arguments);
                                
            } 
            catch(Exception error) {
                result.output = 'ERROR when calling: ' + call.function.name + '( ' + call.function.arguments + ')\n\n' +
                                error.getTypeName() + ' ' + error.getMessage() + ' ' + error.getStackTraceString();
            }
            outputs.add(result);
        }
        submitToolOutput(run.thread_id, run.id, JSON.serialize(outputs));
    }

    // Note: Future was needed after Flow Start
    @future(callout=true)
    private static void submitToolOutput(String threadId, String runId, String outputJson) {
        List<Run.ToolOutput> outputs = (List<Run.ToolOutput>) JSON.deserialize(outputJson,  List<Run.ToolOutput>.class);
        new OpenAiApi('/threads/' + threadId + '/runs/' + runId + '/submit_tool_outputs')
                .body(new Run.ToolOutputs(outputs))
                .post();
    }

    private void notifyUi(Run run) {
        callback = new AssistantCallback__e(Type__c = CALLBACK_RUN_FINISHED, ThreadId__c = run.thread_id);
        EventBus.publish(callback);
    }

    private static String assistantId() {
        Boolean isProductionOrg = ![SELECT IsSandbox FROM Organization LIMIT 1].IsSandbox;
        MyOrgButler__c settings = MyOrgButler__c.getOrgDefaults();
        return (isProductionOrg) ? settings.ProdAssistantId__c : settings.DevAssistantId__c;
    }

    // INNER

    public abstract class Tool {
        protected String threadId;

        public Tool setThreadId(String threadId) {
            this.threadId = threadId;
            return this;
        }

        public abstract String execute(String arguments);
    }
}