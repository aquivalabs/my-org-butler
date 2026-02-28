// Note: Agentforce @InvocableMethod requires global access modifier
@SuppressWarnings('PMD.AvoidGlobalModifier')
global with sharing class PlanForLater {

    @InvocableMethod(label='MyOrgButler: Plan For Later' description='Saves a plan and schedules it for later execution. The agent runs headless and notifies the user with results.')
    global static List<Output> execute(List<Input> inputs) {
        Input input = inputs[0];
        Output result = new Output();

        try {
            String cron = '0 ' + input.schedule;
            String jobName = 'MyOrgButler Plan ' + UUID.randomUUID();

            Id jobId = System.schedule(jobName, cron, new RunMyOrgButler());

            Plan__c plan = new Plan__c();
            plan.Prompt__c = input.prompt;
            plan.JobId__c = String.valueOf(jobId);

            insert as user plan;

            result.planId = plan.Id;
        }
        catch(Exception e) {
            result.error = e.getMessage() + ' (schedule was: ' + input.schedule + ')';
        }

        return new List<Output>{ result };
    }


    // INNER

    global class Input {
        @InvocableVariable(label='Prompt' description='What the agent should do when this plan executes. Be specific and actionable.' required=true)
        global String prompt;

        @InvocableVariable(label='Schedule' description='When to run in the users local time: minute hour dayOfMonth month dayOfWeek optionalYear. e.g. 0 9 ? * MON-FRI for weekdays at 9am.' required=true)
        global String schedule;
    }


    global class Output {
        @InvocableVariable(label='Plan Id' description='The ID of the created Plan record.')
        global String planId;

        @InvocableVariable(label='Error' description='Error message if scheduling failed. Fix the schedule and retry.')
        global String error;
    }
}
