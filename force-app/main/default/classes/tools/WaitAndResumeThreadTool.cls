
public with sharing class WaitAndResumeThreadTool extends MyOrgButler.Tool {
    
    public override String execute(String paramsJson) {
        Integer hoursToWait = new JSONParse(paramsJson).get('hoursToWait').getIntegerValue();

        FlowInterview result = asObject( startWaitFlow(threadId, hoursToWait) );
        return JSON.serialize(result);
    }

    @InvocableMethod(label = 'Resume My Org Butler Thread after wating for a certain time') 
    public static void resumeThread(List<FlowInput> inputs) {
        for(FlowInput input : inputs) {
System.debug(LoggingLevel.ERROR, input);
            new MyOrgButler().resume(input.threadId);
        }
    }
    
    // PRIVATE

    private Flow.Interview startWaitFlow(String threadId, Integer hoursToWait) {
        Map<String, Object> inputs = new Map<String, Object>{
            'threadId' => threadId,
            'hoursToWait' => hoursToWait
        };

        Flow.Interview result = new Flow.Interview.WaitAndResumeThread(inputs);
        result.start();
System.debug(LoggingLevel.ERROR, result);
        return result;
    }


    private FlowInterview asObject(Flow.Interview interview) {
        String guid = interview.getVariableValue('interviewId').toString();
        FlowInterview result = [SELECT Id, InterviewStatus, PauseLabel FROM FlowInterview WHERE Guid = :guid LIMIT 1];
System.debug(LoggingLevel.ERROR, result);
        return result;
    }

    // INNER

    public class FlowInput {
        @InvocableVariable(label='OpenAI Assistant Thread Id')
        public String threadId;

        @InvocableVariable(label='Hours to wait until resuming the thread')
        public Integer hoursToWait;
    }
}