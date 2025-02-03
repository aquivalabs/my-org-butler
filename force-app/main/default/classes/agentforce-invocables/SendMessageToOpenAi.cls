// PMD False Positives: 
// - Only global invocables are seen in installed org
@SuppressWarnings('PMD.AvoidGlobalModifier')
global with sharing class SendMessageToOpenAi {

    @InvocableMethod(label='MyOrgButler: Send User Message to OpenAI' description='Sends the User Message to OpenAI and returns a Run Id. To fetch the asynchronous response directly call the PollOpenAiForResponse action until the Response or an error is available.')
    global static List<Output> execute(List<Input> input) {
        Run newRun = new MyOrgButler().sendMessage(input[0].userMessage);

        Output result = new Output();
        result.threadId = newRun.thread_id;
        result.runId =  newRun.id;
        return new List<Output>{ result };
    }

    // INNER

    global class Input {
        @InvocableVariable(label='User Message' description='The original message from the user.')
        global String userMessage;
    }

    global class Output {
        @InvocableVariable(label='OpenAI Thread Id' description='The Id of the Thread to be passed to the PollOpenAiForResponse action immediatelly after this action finishes.')
        global String threadId;

        @InvocableVariable(label='OpenAI Run Id' description='The Id of the Run to be passed to the PollOpenAiForResponse action immediatelly after this action finishes.')
        global String runId;
    }
}