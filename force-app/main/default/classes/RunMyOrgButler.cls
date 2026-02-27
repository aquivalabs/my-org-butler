
public with sharing class RunMyOrgButler implements Schedulable {


    // PUBLIC

    public void execute(SchedulableContext context) {
        List<Plan__c> plans = (context != null)
            ? [SELECT Prompt__c, Context__c, JobId__c FROM Plan__c WHERE JobId__c = :String.valueOf(context.getTriggerId()) WITH USER_MODE LIMIT 1]
            : [SELECT Prompt__c, Context__c, JobId__c FROM Plan__c ORDER BY CreatedDate DESC LIMIT 1];

        for(Plan__c plan : plans) {
            Map<String, String> contextMap = deserializeContext(plan.Context__c);
            HeadlessAgent.Response response = new HeadlessAgent('MyOrgButler').send(plan.Prompt__c, contextMap);
System.debug(response);
            if(!response.success) {
                new HeadlessAgent('MyOrgButler')
                        .send('Notify the user that a scheduled plan failed with error: ' + response.error);
            }

            cleanUp(plan);
        }
    }


    // PRIVATE

    // Note: CronTrigger is a system object — no CRUD check needed
    @SuppressWarnings('PMD.ApexCRUDViolation')
    private void cleanUp(Plan__c plan) {
        CronTrigger job = [SELECT NextFireTime FROM CronTrigger WHERE Id = :plan.JobId__c];

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
