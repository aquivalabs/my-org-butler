public with sharing class MyOrgButler implements Queueable, Database.AllowsCallouts {

    private static final String ASSISTANT_ID = assistantId();
    private static final Integer WAIT_TIME = 3000;
    private final static Map<String, Tool> TOOLS = new Map<String, Tool>{ 
                                                        'Call_Salesforce_API' => new CallSalesforceApiTool(),
                                                        'Notify_User' => new NotifyUserTool()  };
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

    public void respond(String question, String context) {
        Message.create(settings.ThreadId__c, new Message(question));
        persistNewRun(context);
        pollOrQueue();
    }

    public void execute(QueueableContext context) {
        poll();
    }

    // PRIVATE

    private void persistNewThread() {
        Thread thread = Thread.create();
        settings.ThreadId__c = thread.id;
        settings.RunId__c = null;
        upsert as system settings;
    }

    private void persistNewRun(String context) {
        Run newRun = new Run(settings.ThreadId__c, ASSISTANT_ID);
        newRun.additional_instructions = prepareAdditionalInstructions(context);
        newRun = Run.create(settings.ThreadId__c, newRun);

        settings.RunId__c = newRun.id;
        update as system settings;
    }

    private void pollOrQueue() {
        if(limitRisk()) {
            System.enqueueJob(this);
        }
        else {
            sleep(WAIT_TIME);
            poll();
        }
    }

    private Boolean limitRisk() {
        return (Limits.getCallouts() > Limits.getLimitCallouts() - 10 ||
                Limits.getCpuTime() > Limits.getLimitCpuTime() - 5 * WAIT_TIME);
    }
    
    private void poll() {
        Run run = Run.retrieve(settings.ThreadId__c, settings.RunId__c);

        if(run.isPending()) {
            pollOrQueue();
        } 
        else if(run.requestsTool()) {
            runToolAndCallback(run);
            pollOrQueue();
        } 
        else if(run.isCompletedOrFailed()) {
            notifyUi(run);
        }
    }

    private void runToolAndCallback(Run run) {
        List<Run.ToolOutput> outputs = new List<Run.ToolOutput>();

        for(Run.ToolCall current : run.required_action.submit_tool_outputs.tool_calls) {
            Run.ToolOutput result = new Run.ToolOutput(current.id);

            if(!TOOLS.containsKey(current.function.name)) {
                result.output = 'ERROR: There is no such tool/action/function : ' + current.function.name;
            }

            try {
                result.output = TOOLS.get(current.function.name).execute(current.function.arguments);
            } 
            catch(Exception error) {
                result.output = 'ERROR when calling: ' + current.function.name + '( ' + current.function.arguments + ')\n\n' +
                                error.getTypeName() + ' ' + error.getMessage() + ' ' + error.getStackTraceString();
                System.debug(LoggingLevel.ERROR, result.output);
            }

            outputs.add(result);
        }

        new OpenAiApi('/threads/' + run.thread_id + '/runs/' + run.id + '/submit_tool_outputs')
                .body(new Run.ToolOutputs(outputs))
                .post();
    }

    private void notifyUi(Run run) {
        callback = new AssistantCallback__e(ThreadId__c = run.thread_id, RunId__c = run.id);
        EventBus.publish(callback);
    }

    // PMD False Positive: Empty while is part of idle algortihm of https://salesforce.stackexchange.com/a/302152/256
    @SuppressWarnings('PMD')
    private void sleep(Integer milliseconds) {
        Long startTime = DateTime.now().getTime();
        while(DateTime.now().getTime() - startTime < milliseconds); 
    }

    private String prepareAdditionalInstructions(String context) {
        return 'Execute the users request using this context information. Specially important is the currentPage as it tells you what the user sees and refers to. So when you are asked about to explain or summarize always think about what the user sees and might refer to:\n' +
                '\nuserId=' + UserInfo.getUserId() +
                '\nuserFirstName=' + UserInfo.getFirstName() +
                '\nuserLastName=' + UserInfo.getLastName() +
                '\nuserLanguage=' + UserInfo.getLanguage() +
                '\nuserDateTime=' + System.now() +
                '\nuserEmail=' + UserInfo.getUserEmail() +
                '\baseUrlForLinks=' + URL.getSalesforceBaseUrl().toExternalForm() +
                '\ncurrentPage=' +  context;
    }

    private static String assistantId() {
        Boolean isProductionOrg = ![SELECT IsSandbox FROM Organization LIMIT 1].IsSandbox;
        MyOrgButler__c settings = MyOrgButler__c.getOrgDefaults();
        return (isProductionOrg) ? settings.ProdAssistantId__c : settings.DevAssistantId__c;
    }

    // INNER

    public interface Tool {
        String execute(String arguments);
    }
}