// PMD False Positives: 
// - Only global invocables are seen in installed org
@SuppressWarnings('PMD.AvoidGlobalModifier')
global with sharing class PollOpenAiForResponse {// PMD False Positives: 

    @InvocableMethod(label='MyOrgButler: Poll OpenAI for a response' description='Poll OpenAI with a Run Id to check if the asynchronous response is already available. Call this action multiple times until a final success or error is available.')
    global static List<Output> execute(List<Input> input) {
        new Sleep(3000);
        Output result = new Output();
        result.response = new OpenAiAssistant(input[0].threadId, input[0].runId)
                                    .pollForResponse();
        return new List<Output>{ result };
    }

    // INNER

    global class Input {
        @InvocableVariable(label='OpenAI Thread Id' description='The OpenAI Thread Id under which the User Message was sent to.')
        global String threadId;

        @InvocableVariable(label='OpenAI Run Id' description='The OpenAI Run Id under which the User Message was sent to.')
        global String runId;
    }

    global class Output {
        @InvocableVariable(label='OpenAI Response' description='Successful Response or an Error')
        global String response;
    }
}