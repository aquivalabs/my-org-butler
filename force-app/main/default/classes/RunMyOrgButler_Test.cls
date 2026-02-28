@IsTest
private class RunMyOrgButler_Test {


    @IsTest
    private static void executesWithPlanId() {

        // Setup
        Plan__c plan = new Plan__c();
        plan.Prompt__c = 'Summarize account';
        plan.JobId__c = 'placeholder';
        insert plan;


        // Exercise
        RunMyOrgButler butler = new RunMyOrgButler();
        butler.execute(plan.Id);


        // Verify
        Assert.isTrue(butler.response.success);
        Assert.areEqual(0, [SELECT COUNT() FROM Plan__c]);
    }


    @IsTest
    private static void executeFromSchedulable() {

        // Setup
        Id jobId = jobId();

        Plan__c plan = new Plan__c();
        plan.Prompt__c = 'Summarize account';
        plan.JobId__c = jobId;
        insert plan;


        // Exercise
        RunMyOrgButler butler = new RunMyOrgButler();
        butler.execute(jobId);


        // Verify
        Assert.isTrue(butler.response.success);
        Assert.areEqual(0, [SELECT COUNT() FROM Plan__c]);
    }


    @IsTest
    private static void execute() {

        // Setup
        Plan__c plan = new Plan__c();
        plan.Prompt__c = 'Summarize account';
        plan.JobId__c = 'placeholder';
        insert plan;

        RunMyOrgButler.Input input = new RunMyOrgButler.Input();
        input.planOrJobId = plan.Id;


        // Exercise
        List<RunMyOrgButler.Output> outputs = RunMyOrgButler.execute(new List<RunMyOrgButler.Input>{ input });


        // Verify
        Assert.isTrue(outputs[0].success);
        Assert.areEqual(0, [SELECT COUNT() FROM Plan__c]);
    }


    // HELPER

    private static Id jobId() {
        Id result = System.schedule('Test Plan', '0 0 9 ? * MON', new RunMyOrgButler());

        // Note: Abort needed so cleanUp sees no NextFireTime and deletes the plan
        System.abortJob(result);

        return result;
    }
}
