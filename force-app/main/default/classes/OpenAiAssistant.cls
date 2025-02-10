public with sharing class OpenAiAssistant {

    private String threadId;
    private String runId;

    // CONSTRUCTOR

    public OpenAiAssistant() {
        Thread thread = Thread.create();

        threadId = thread.id;
        runId = runId;
    }

    public OpenAiAssistant(String threadId, String runId) {
        this.threadId = threadId;
        this.runId = runId;
    }

    // PUBLIC

    public Run sendMessage(String content) {
        Message.create(threadId, new Message(content));
        Run run = persistNewRun();
        new Sleep(3000);
        return run;
    }


    public String pollForResponse() {
        String result = null;

        Run run = Run.retrieve(threadId, runId);
        if(run.isPending()) {
            result = 'Response for ThreadId: ' + threadId + ' and RunId: ' + runId + ' pending.';
        } 
        else if(run.isCompletedOrFailed()) {
            List<Message> messages = Message.retrieve(threadId).data;
            result = messages[0].content[0].text.value;
        }
        else {
            throw new ApplicationException('OpenAI Run in invalid state: ' + run);
        }

        return result;
    }


    // PRIVATE

    private Run persistNewRun() {
        Run result = new Run(threadId, MyOrgButler.ASSISTANT_ID);
        result = Run.create(threadId, result);

        runId = result.id;

        return result;
    }
}