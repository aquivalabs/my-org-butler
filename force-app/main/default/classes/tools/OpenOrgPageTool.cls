public with sharing class OpenOrgPageTool extends MyOrgButler.Tool {

    private final String CALLBACK_NAVIGATE = 'NAVIGATE';

    public override String execute(String pageReferenceJson) {
        AssistantCallback__e callback = new AssistantCallback__e(Type__c = CALLBACK_NAVIGATE, ThreadId__c = threadId, Payload__c = pageReferenceJson);
        Database.SaveResult result = EventBus.publish(callback);
        return JSON.serialize(result);
    }
}