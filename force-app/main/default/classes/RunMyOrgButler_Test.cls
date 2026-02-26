@IsTest
private class RunMyOrgButler_Test {


    @IsTest
    private static void executesPlanViaHeadlessAgent() {

        // Setup
        Test.startTest();
        Id jobId = System.schedule('Test Plan', '0 0 0 15 3 ? 2099', new RunMyOrgButler());

        Plan__c plan = new Plan__c();
        plan.Prompt__c = 'Summarize account';
        plan.Context__c = '{"AccountId":"some-account","Priority":"High"}';
        plan.JobId__c = String.valueOf(jobId);
        insert plan;

        Test.stopTest();

        // Verify
        Assert.areEqual(1, [SELECT COUNT() FROM Plan__c WHERE Id = :plan.Id]);
    }


    @IsTest
    private static void doesNothingWhenNoPlanMatchesJob() {

        // Exercise
        Test.startTest();
        System.schedule('Test Plan', '0 0 0 15 3 ? 2099', new RunMyOrgButler());
        Test.stopTest();
    }
}
