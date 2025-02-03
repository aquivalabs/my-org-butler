@IsTest
private class PollOpenAiForResponse_Test {

    @IsTest
    private static void execute() {

        // Setup
        Run run = new Run('123', 'abc');
        run.id = '987';
        run.status = 'completed';

        Message.Messages messages = new Message.Messages();
        messages.data = new List<Message>{ new Message('The answer is 42.') };

        new HttpMock()
                .get('aquiva_os__OpenAiApi/v1/threads/abc/runs/123', run)
                .get('aquiva_os__OpenAiApi/v1/threads/abc/messages', messages)
                .mock();

        PollOpenAiForResponse.Input input = new PollOpenAiForResponse.Input();
        input.threadId = 'abc';
        input.runId = '123';


        // Exercise
        Test.startTest();
        PollOpenAiForResponse.Output output = PollOpenAiForResponse.execute( new List<PollOpenAiForResponse.Input>{ input } )[0];
        Test.stopTest();

        
        // Verify
        System.assert(output.response.contains('42'));
    }
}