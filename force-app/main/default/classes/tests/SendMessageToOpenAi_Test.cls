@IsTest
private class SendMessageToOpenAi_Test {

    @IsTest
    private static void execute() {

        // Setup
        Run run = new Run('abc', 'any');
        run.id = '123';
        run.status = 'in_progress';

        Message.Messages messages = new Message.Messages();
        messages.data = new List<Message>{ new Message('The answer is 41.') };

        new HttpMock()
                .post('aquiva_os__OpenAiApi/v1/threads', new Thread().id('abc'))
                .post('aquiva_os__OpenAiApi/v1/threads/abc/messages', new Message('What is the answer to all questions?'))
                .post('aquiva_os__OpenAiApi/v1/threads/abc/runs', run)
                .mock();

        SendMessageToOpenAi.Input input = new SendMessageToOpenAi.Input();
        input.userMessage = 'What is the answer to all questions?';


        // Exercise
        Test.startTest();
        SendMessageToOpenAi.Output output = SendMessageToOpenAi.execute( new List<SendMessageToOpenAi.Input>{ input } )[0];
        Test.stopTest();

        
        // Verify
        System.assertEquals('abc', output.threadId);
        System.assertEquals('123', output.runId);
    }
}