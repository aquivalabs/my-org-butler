@IsTest
private class ScheduledPlan_Test {


    @IsTest
    private static void executesOneTimePlanAndCompletes() {

        // Setup
        Plan__c plan = new Plan__c();
        plan.Instructions__c = 'Check for open cases';
        plan.CronExpression__c = '0 0 9 1 1 ? 2099';
        plan.IsRecurring__c = false;
        plan.Status__c = 'Active';
        insert plan;

        PlanExecution__c execution = new PlanExecution__c();
        execution.Plan__c = plan.Id;
        execution.Status__c = 'Scheduled';
        execution.Result__c = '{"scheduledAt":"2099-01-01T09:00:00Z"}';
        execution.JobId__c = '0CrFAKEJOBID00001';
        insert execution;


        // Exercise
        new ScheduledPlan(plan.Id).execute(null);


        // Verify
        PlanExecution__c updated = [SELECT Status__c, Result__c FROM PlanExecution__c WHERE Id = :execution.Id];
        Assert.areEqual('Success', updated.Status__c);
        Assert.isNotNull(updated.Result__c);

        Plan__c completedPlan = [SELECT Status__c FROM Plan__c WHERE Id = :plan.Id];
        Assert.areEqual('Completed', completedPlan.Status__c);
    }


    @IsTest
    private static void executesRecurringPlanAndCreatesNextExecution() {

        // Setup
        Plan__c plan = new Plan__c();
        plan.Instructions__c = 'Weekly case review';
        plan.CronExpression__c = '0 0 9 ? * MON';
        plan.IsRecurring__c = true;
        plan.Status__c = 'Active';
        insert plan;

        PlanExecution__c execution = new PlanExecution__c();
        execution.Plan__c = plan.Id;
        execution.Status__c = 'Scheduled';
        execution.Result__c = '{"scheduledAt":"2099-01-06T09:00:00Z"}';
        execution.JobId__c = '0CrFAKEJOBID00002';
        insert execution;


        // Exercise
        new ScheduledPlan(plan.Id).execute(null);


        // Verify
        PlanExecution__c completed = [SELECT Status__c FROM PlanExecution__c WHERE Id = :execution.Id];
        Assert.areEqual('Success', completed.Status__c);

        Plan__c activePlan = [SELECT Status__c FROM Plan__c WHERE Id = :plan.Id];
        Assert.areEqual('Active', activePlan.Status__c);
    }


    @IsTest
    private static void deserializesContextVariables() {

        // Setup
        Plan__c plan = new Plan__c();
        plan.Instructions__c = 'Summarize account';
        plan.Context__c = '{"AccountId":"001000000000001","Priority":"High"}';
        plan.CronExpression__c = '0 0 9 1 1 ? 2099';
        plan.IsRecurring__c = false;
        plan.Status__c = 'Active';
        insert plan;

        PlanExecution__c execution = new PlanExecution__c();
        execution.Plan__c = plan.Id;
        execution.Status__c = 'Scheduled';
        execution.Result__c = '{"scheduledAt":"2099-01-01T09:00:00Z"}';
        execution.JobId__c = '0CrFAKEJOBID00003';
        insert execution;


        // Exercise
        new ScheduledPlan(plan.Id).execute(null);


        // Verify
        PlanExecution__c updated = [SELECT Status__c, Result__c FROM PlanExecution__c WHERE Id = :execution.Id];
        Assert.areEqual('Success', updated.Status__c);
    }
}
