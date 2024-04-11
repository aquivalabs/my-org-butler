
public with sharing class WaitAndResumeThreadTool extends MyOrgButler.Tool implements Schedulable {

    public override String execute(String paramsJson) {
        Integer minutesToWait = new JSONParse(paramsJson).get('minutesToWait').getIntegerValue();
        String cronExp = DateTime.now().addMinutes(minutesToWait).format('ss mm HH dd MM ? yyyy');
        WaitAndResumeThreadTool tool = (WaitAndResumeThreadTool) new WaitAndResumeThreadTool().setThreadId(threadId);
        
        String jobId = System.schedule('MyOrgButler: Pause for ' + minutesToWait + ' minutes:', cronExp, tool);
        return '{ "scheduledJobId" : "' + jobId + '" }';
    }

    public void execute(SchedulableContext context) {
        resume(threadId);

        // Note: Remove outdated Cron Job
        System.abortJob( context.getTriggerId() );
    }

    // PRIVATE 

    // Note: No callouts from Schedulable
    @future(callout=true)
    private static void resume(String threadId) {
        new MyOrgButler().resume(threadId);
    }
}