// Note: CronTrigger is a system object — no CRUD check needed
@SuppressWarnings('PMD.ApexCRUDViolation')
public with sharing class RunMyOrgButler implements Schedulable {

    private static final String AGENT_NAME = 'MyOrgButler';
    private static final String NOTIFICATION_INSTRUCTION = '\n\nIMPORTANT: Deliver results by notifying the user. If anything fails, notify the user about the error.';


    // PUBLIC

    public void execute(SchedulableContext context) {
        String jobId = String.valueOf(context.getTriggerId());

        for(Plan__c plan : [SELECT Prompt__c, Context__c FROM Plan__c WHERE JobId__c = :jobId WITH USER_MODE LIMIT 1]) {
            Map<String, String> contextMap = deserializeContext(plan.Context__c);

            HeadlessAgent.Response response = new HeadlessAgent(AGENT_NAME).send(plan.Prompt__c + NOTIFICATION_INSTRUCTION, contextMap);

            if(!response.success) {
                new HeadlessAgent(AGENT_NAME).send(
                    'Notify the user that a scheduled plan failed with error: ' + response.error
                );
            }

            deleteIfOneTime(plan, jobId);
        }
    }


    // PRIVATE

    private void deleteIfOneTime(Plan__c plan, String jobId) {
        if(Test.isRunningTest()) {
            return;
        }

        CronTrigger job = [SELECT NextFireTime FROM CronTrigger WHERE Id = :jobId];

        if(job.NextFireTime == null) {
            delete as user plan;
        }
    }


    private Map<String, String> deserializeContext(String contextJson) {
        Map<String, String> result = new Map<String, String>();

        if(String.isNotBlank(contextJson)) {
            result = (Map<String, String>) JSON.deserialize(contextJson, Map<String, String>.class);
        }

        return result;
    }
}
