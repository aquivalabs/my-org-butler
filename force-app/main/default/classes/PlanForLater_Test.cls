@IsTest
private class PlanForLater_Test {


    @IsTest
    private static void createsPlanWithPromptAndContext() {

        // Setup
        PlanForLater.Input input = new PlanForLater.Input();
        input.prompt = 'Check for unassigned high-priority cases and notify me';
        input.context = '{"AccountId":"some-account"}';
        input.cronExpression = '0 0 9 ? * MON-FRI';


        // Exercise
        List<PlanForLater.Output> outputs = PlanForLater.execute(new List<PlanForLater.Input>{ input });


        // Verify
        Plan__c plan = [SELECT Prompt__c, Context__c, JobId__c FROM Plan__c WHERE Id = :outputs[0].planId];

        Assert.areEqual('Check for unassigned high-priority cases and notify me', plan.Prompt__c);
        Assert.areEqual('{"AccountId":"some-account"}', plan.Context__c);
        Assert.isNotNull(plan.JobId__c, 'Plan should have a scheduled job');
    }
}
