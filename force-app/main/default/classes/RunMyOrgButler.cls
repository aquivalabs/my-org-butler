
public with sharing class RunMyOrgButler implements Schedulable {

    @TestVisible
    private HeadlessAgent.Response response;


    // PUBLIC

    public void execute(SchedulableContext ctx) {
        execute(ctx.getTriggerId());
    }


    public void execute(Id planOrJobId) {
        Plan__c plan = [SELECT Prompt__c, Context__c, JobId__c
                        FROM Plan__c
                        WHERE Id = :planOrJobId OR JobId__c = :planOrJobId
                        WITH USER_MODE
                        LIMIT 1];

        response = new HeadlessAgent('MyOrgButler').send(plan.Prompt__c, context(plan));
        if(!response.success) {
            new HeadlessAgent('MyOrgButler')
                    .send('Notify the user that a scheduled plan failed with error: ' + response.error);
        }

        cleanUp(plan);
    }


    // PRIVATE

    private Map<String, String> context(Plan__c plan) {
        Map<String, String> result = new Map<String, String>();

        if(String.isNotBlank(plan.Context__c)) {
            result = (Map<String, String>) JSON.deserialize(plan.Context__c, Map<String, String>.class);
        }

        return result;
    }


    // Note: CronTrigger is a system object — no CRUD check needed
    @SuppressWarnings('PMD.ApexCRUDViolation')
    private void cleanUp(Plan__c plan) {
        List<CronTrigger> jobs = [SELECT NextFireTime FROM CronTrigger WHERE Id = :plan.JobId__c];

        if(jobs.isEmpty() || jobs[0].NextFireTime == null) {
            delete as user plan;
        }
    }
}
