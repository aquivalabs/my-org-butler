@IsTest
private class PollOpenAiForResponse_Test {

    @IsTest
    private static void execute() {

        // Setup
        insert new MyOrgButler__c(SetupOwnerId = UserInfo.getUserId(), ThreadId__c = 't1', RunId__c = 'r1');  

        Run run = new Run('t1', 'a1');
        run.id = 'r1';
        run.status = 'completed';

        Message.Messages messages = new Message.Messages();
        messages.data = new List<Message>{ new Message('The answer is 42.') };

        new HttpMock()
                .get('aquiva_os__OpenAiApi/v1/threads/t1/runs/r1').body(run).statusCodeOk()
                .get('aquiva_os__OpenAiApi/v1/threads/t1/messages').body(messages).statusCodeOk()
                .mock();

        PollOpenAiForResponse.Input input = new PollOpenAiForResponse.Input();
        input.threadId = 't1';
        input.runId = 'r1';

        // Exercise
        Test.startTest();   
        PollOpenAiForResponse.Output output = PollOpenAiForResponse.execute( new List<PollOpenAiForResponse.Input>{ input } )[0];
        Test.stopTest();

        
        // Verify
        System.assert(output.response.contains('42'));
    }
}