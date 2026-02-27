// Note: Agentforce @InvocableMethod requires global access modifier
@SuppressWarnings('PMD.AvoidGlobalModifier')
global with sharing class PlanForLater {

    @InvocableMethod(label='MyOrgButler: Plan For Later' description='Saves a plan and schedules it for later execution. The agent runs headless and notifies the user with results.')
    global static List<Output> execute(List<Input> inputs) {
        Input input = inputs[0];

        String jobName = 'MyOrgButler Plan ' + UUID.randomUUID();
        Id jobId = System.schedule(jobName, '0 ' + input.schedule, new RunMyOrgButler());

        Plan__c plan = new Plan__c();
        plan.Prompt__c = input.prompt;
        plan.Context__c = input.context;
        plan.JobId__c = String.valueOf(jobId);

        insert as user plan;

        Output result = new Output();
        result.planId = plan.Id;

        return new List<Output>{ result };
    }


    // INNER

    global class Input {
        @InvocableVariable(label='Prompt' description='What the agent should do when this plan executes. Be specific and actionable.' required=true)
        global String prompt;

        @InvocableVariable(label='Context' description='JSON object with context variables like record IDs. e.g. {"AccountId":"001xx"}' required=false)
        global String context;

        @InvocableVariable(label='Schedule' description='When to run in the users local time: minute hour dayOfMonth month dayOfWeek optionalYear. e.g. 0 9 ? * MON-FRI for weekdays at 9am.' required=true)
        global String schedule;
    }


    global class Output {
        @InvocableVariable(label='Plan Id' description='The ID of the created Plan record.')
        global String planId;
    }
}
