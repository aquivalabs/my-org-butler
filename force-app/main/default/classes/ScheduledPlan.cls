public with sharing class ScheduledPlan implements Schedulable {

    private static final String AGENT_NAME = 'MyOrgButler';

    private Id planId;


    // CONSTRUCTOR

    public ScheduledPlan(Id planId) {
        this.planId = planId;
    }


    // PUBLIC STATIC

    public static Id execute(Id planId, String cronExpression) {
        String jobName = 'Plan: ' + planId + ' ' + Datetime.now().getTime();
        Id jobId = System.schedule(jobName, cronExpression, new ScheduledPlan(planId));

        createScheduledExecution(planId, jobId);

        return jobId;
    }


    // PUBLIC

    public void execute(SchedulableContext context) {
        Plan__c plan = [SELECT Instructions__c, Context__c, IsRecurring__c, CronExpression__c
                        FROM Plan__c
                        WHERE Id = :planId
                        WITH USER_MODE];

        PlanExecution__c execution = scheduledExecution();

        Map<String, String> contextMap = deserializeContext(plan.Context__c);
        HeadlessAgent.Response response = new HeadlessAgent(AGENT_NAME).prompt(plan.Instructions__c, contextMap);

        if(response.success) {
            execution.Status__c = 'Success';
            execution.Result__c = response.text;
        }
        else {
            execution.Status__c = 'Failed';
            execution.Result__c = response.error;
        }

        Database.update(execution, AccessLevel.USER_MODE);

        if(plan.IsRecurring__c) {
            execute(planId, plan.CronExpression__c);
        }
        else {
            plan.Status__c = 'Completed';
            Database.update(plan, AccessLevel.USER_MODE);
        }
    }


    // PRIVATE STATIC

    private static void createScheduledExecution(Id planId, Id jobId) {
        PlanExecution__c execution = new PlanExecution__c();
        execution.Plan__c = planId;
        execution.Status__c = 'Scheduled';
        execution.JobId__c = String.valueOf(jobId);
        execution.Result__c = '{"scheduledAt":"' + Datetime.now().formatGmt('yyyy-MM-dd\'T\'HH:mm:ss\'Z\'') + '"}';

        Database.insert(execution, AccessLevel.USER_MODE);
    }


    // PRIVATE

    private PlanExecution__c scheduledExecution() {
        PlanExecution__c result = [SELECT Id, Status__c, Result__c, JobId__c
                                   FROM PlanExecution__c
                                   WHERE Plan__c = :planId AND Status__c = 'Scheduled'
                                   WITH USER_MODE
                                   ORDER BY CreatedDate DESC
                                   LIMIT 1];

        return result;
    }


    private Map<String, String> deserializeContext(String contextJson) {
        Map<String, String> result = new Map<String, String>();

        if(String.isNotBlank(contextJson)) {
            result = (Map<String, String>) JSON.deserialize(contextJson, Map<String, String>.class);
        }

        return result;
    }
}
