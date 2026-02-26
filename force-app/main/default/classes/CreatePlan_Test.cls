@IsTest
private class CreatePlan_Test {


    @IsTest
    private static void createsActivePlanRecord() {

        // Setup
        CreatePlan.Input input = new CreatePlan.Input();
        input.instructions = 'Check for unassigned high-priority cases';
        input.cronExpression = '0 0 9 ? * MON-FRI';
        input.isRecurring = true;


        // Exercise
        List<CreatePlan.Output> outputs = CreatePlan.execute(new List<CreatePlan.Input>{ input });


        // Verify
        Plan__c plan = [SELECT Instructions__c, CronExpression__c, IsRecurring__c, Status__c
                        FROM Plan__c
                        WHERE Id = :outputs[0].planId];

        Assert.areEqual('Check for unassigned high-priority cases', plan.Instructions__c);
        Assert.areEqual('0 0 9 ? * MON-FRI', plan.CronExpression__c);
        Assert.isTrue(plan.IsRecurring__c);
        Assert.areEqual('Active', plan.Status__c);
    }


    @IsTest
    private static void createsOneTimePlanWithDefaults() {

        // Setup
        CreatePlan.Input input = new CreatePlan.Input();
        input.instructions = 'Send weekly summary';
        input.cronExpression = '0 0 17 26 2 ? 2026';


        // Exercise
        List<CreatePlan.Output> outputs = CreatePlan.execute(new List<CreatePlan.Input>{ input });


        // Verify
        Plan__c plan = [SELECT IsRecurring__c, Status__c FROM Plan__c WHERE Id = :outputs[0].planId];

        Assert.isFalse(plan.IsRecurring__c);
        Assert.areEqual('Active', plan.Status__c);
    }


    @IsTest
    private static void storesContextJson() {

        // Setup
        CreatePlan.Input input = new CreatePlan.Input();
        input.instructions = 'Summarize this account';
        input.context = '{"AccountId":"001000000000001"}';
        input.cronExpression = '0 0 9 ? * MON';


        // Exercise
        List<CreatePlan.Output> outputs = CreatePlan.execute(new List<CreatePlan.Input>{ input });


        // Verify
        Plan__c plan = [SELECT Context__c FROM Plan__c WHERE Id = :outputs[0].planId];

        Assert.areEqual('{"AccountId":"001000000000001"}', plan.Context__c);
    }
}
