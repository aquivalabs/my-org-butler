// Note: Agentforce @InvocableMethod requires global access modifier
@SuppressWarnings('PMD.AvoidGlobalModifier')
global with sharing class RunMyOrgButler implements Schedulable {

    @TestVisible
    private HeadlessAgent.Response response;


    // PUBLIC

    @InvocableMethod(label='MyOrgButler: Run My Org Butler' description='Delegates a task to a headless sub-butler that works in the background and notifies the user when done.')
    global static List<Output> execute(List<Input> inputs) {
        RunMyOrgButler runner = new RunMyOrgButler();
        runner.execute(inputs[0].planOrJobId);

        Output result = new Output();
        result.success = runner.response.success;
        result.error = runner.response.error;
        return new List<Output>{ result };
    }


    public void execute(SchedulableContext ctx) {
        execute(ctx.getTriggerId());
    }

    public void execute(Id planOrJobId) {
        Plan__c plan = [SELECT Prompt__c, JobId__c
                        FROM Plan__c
                        WHERE Id = :planOrJobId OR JobId__c = :planOrJobId
                        WITH USER_MODE
                        LIMIT 1];

        response = new HeadlessAgent('MyOrgButler').send(plan.Prompt__c);

        if(!response.success) {
            new HeadlessAgent('MyOrgButler')
                    .send('Notify the user that a scheduled plan failed with error: ' + response.error);
        }

        cleanUp(plan);
    }


    // INNER

    global class Input {
        @InvocableVariable(label='Plan Or Job Id' description='The ID of the Plan record or the scheduled Job ID to delegate to the sub-butler.' required=true)
        global String planOrJobId;
    }


    global class Output {
        @InvocableVariable(label='Success' description='Whether the delegation to the headless sub-butler succeeded.')
        global Boolean success;

        @InvocableVariable(label='Error' description='Error message if the delegation failed.')
        global String error;
    }


    // PRIVATE

    // Note: CronTrigger is a system object — no CRUD check needed
    @SuppressWarnings('PMD.ApexCRUDViolation')
    private void cleanUp(Plan__c plan) {
        List<CronTrigger> jobs = [SELECT NextFireTime FROM CronTrigger WHERE Id = :plan.JobId__c];

        if(jobs.isEmpty() || jobs[0].NextFireTime == null) {
            delete as user plan;
        }
    }
}
