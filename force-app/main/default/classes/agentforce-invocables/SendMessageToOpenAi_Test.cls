@IsTest
private class SendMessageToOpenAi_Test {

    @IsTest
    private static void execute() {

        // Setup
        insert new MyOrgButler__c(SetupOwnerId = UserInfo.getUserId(), ThreadId__c = 't1');  

        Run run = new Run('t1', 'a1');
        run.id = 'r1';
        run.status = 'in_progress';

        Message.Messages messages = new Message.Messages();
        messages.data = new List<Message>{ new Message('The answer is 41.') };

        new HttpMock()
                .post('aquiva_os__OpenAiApi/v1/threads', new Thread().id('t1'))
                .post('aquiva_os__OpenAiApi/v1/threads/t1/messages', new Message('What is the answer to all questions?'))
                .post('aquiva_os__OpenAiApi/v1/threads/t1/runs', run)
                .mock();

        SendMessageToOpenAi.Input input = new SendMessageToOpenAi.Input();
        input.userMessage = 'What is the answer to all questions?';


        // Exercise
        Test.startTest();
        SendMessageToOpenAi.Output output = SendMessageToOpenAi.execute( new List<SendMessageToOpenAi.Input>{ input } )[0];
        Test.stopTest();

        
        // Verify
        System.assertEquals('t1', output.threadId);
        System.assertEquals('r1', output.runId);

        MyOrgButler__c settings = MyOrgButler__c.getInstance();
        System.assertEquals('t1', settings.ThreadId__c);
        System.assertEquals('r1', settings.RunId__c);
    }
}