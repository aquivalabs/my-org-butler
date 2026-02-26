// Note: Agentforce requires Global
@SuppressWarnings('PMD.AvoidGlobalModifier')
global with sharing class CreatePlan {

    @InvocableMethod(label='MyOrgButler: Create Plan' description='Creates a scheduled plan that the headless agent will execute at the specified time.')
    global static List<Output> execute(List<Input> inputs) {
        Input input = inputs[0];

        Plan__c plan = new Plan__c();
        plan.Instructions__c = input.instructions;
        plan.Context__c = input.context;
        plan.CronExpression__c = input.cronExpression;
        plan.IsRecurring__c = (input.isRecurring != null) ? input.isRecurring : false;
        plan.Status__c = 'Active';

        Database.insert(plan, AccessLevel.USER_MODE);

        if(!Test.isRunningTest()) {
            ScheduledPlan.execute(plan.Id, input.cronExpression);
        }

        Output result = new Output();
        result.planId = plan.Id;

        return new List<Output>{ result };
    }


    // INNER

    global class Input {
        @InvocableVariable(label='Instructions' description='What the agent should do when this plan executes. Be specific and actionable.' required=true)
        global String instructions;

        @InvocableVariable(label='Context' description='JSON object with context variables like record IDs or parameters. e.g. {"AccountId":"001xx","Priority":"High"}' required=false)
        global String context;

        @InvocableVariable(label='Cron Expression' description='Salesforce cron expression for when to execute. e.g. 0 0 9 ? * MON-FRI for weekdays at 9am.' required=true)
        global String cronExpression;

        @InvocableVariable(label='Is Recurring' description='Set to true for repeating schedules. False for one-time execution.' required=false)
        global Boolean isRecurring = false;
    }


    global class Output {
        @InvocableVariable(label='Plan Id' description='The ID of the created Plan record.')
        global String planId;
    }
}
