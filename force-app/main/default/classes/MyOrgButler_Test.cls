@IsTest
private class MyOrgButler_Test {
    
    @IsTest
    private static void initCreatesAndPersistsNewThread() {
        // Setup
        Thread t = new Thread().id('t1');
        new HttpMock()
                .post('aquiva_os__OpenAiApi/v1/threads').body(t).statusCodeOk()
                .mock();

        // Exercise
        Test.startTest();
        new MyOrgButler();
        Test.stopTest();

        // Verify
        MyOrgButler__c settings = MyOrgButler__c.getInstance(UserInfo.getUserId());
        System.assertNotEquals(null, settings);
        System.assertEquals(t.id, settings.ThreadId__c);
        System.assertEquals(null, settings.RunId__c);
    }

    @IsTest
    private static void resetCleansUpCorrectly() {
        // Setup
        insert new MyOrgButler__c(SetupOwnerId = UserInfo.getUserId(), ThreadId__c = 't1', RunId__c = 'r1');
        
        Thread t = new Thread().id('t2');

        new HttpMock()
                .post('aquiva_os__OpenAiApi/v1/threads/t1/runs/r1/cancel').body(true).statusCodeOk()
                .deletex('aquiva_os__OpenAiApi/v1/threads/t1').body(true).statusCodeOk()
                .post('aquiva_os__OpenAiApi/v1/threads').body(t).statusCodeOk()
                .mock();

        // Exercise
        Test.startTest();
        new MyOrgButler().reset();
        Test.stopTest();

        // Verify
        MyOrgButler__c settings = MyOrgButler__c.getInstance(UserInfo.getUserId());
        System.assertNotEquals(null, settings);
        System.assertEquals('t2', settings.ThreadId__c);
        System.assertEquals(null, settings.RunId__c);
    }

    @IsTest
    private static void messages() {
        // Setup
        insert new MyOrgButler__c(SetupOwnerId = UserInfo.getUserId(), ThreadId__c = 't1');  

        Message.Messages messages = new Message.Messages();
        messages.data = new List<Message>{ new Message('Hi') };

        new HttpMock()
                .get('aquiva_os__OpenAiApi/v1/threads/t1/messages').body(messages).statusCodeOk()
                .mock();

        // Exercise
        Test.startTest();
        List<Message> retrieved = new MyOrgButler().messages('any');
        Test.stopTest();
        
        // Verify
        System.assertEquals(1, retrieved.size());
        System.assertEquals('Hi', retrieved[0].content[0].text.value);
    }

    @IsTest
    private static void steps() {
        // Setup
        insert new MyOrgButler__c(SetupOwnerId = UserInfo.getUserId(), ThreadId__c = 't1');  

        Message m = new Message('Hi');
        m.run_id = 'r1';
        Message.Messages messages = new Message.Messages();
        messages.data = new List<Message>{ m };

        new HttpMock()
                .get('aquiva_os__OpenAiApi/v1/threads/t1/runs/r1/steps').body(new Run.Steps('completed')).statusCodeOk()
                .mock();

        // Exercise
        Test.startTest();
        Run.Steps steps = new MyOrgButler().steps('r1');
        Test.stopTest();
        
        // Verify
        System.assertEquals(1, steps.data.size());
        System.assertEquals('completed', steps.data[0].status);
    }

    @IsTest
    private static void respond() {
        // Setup
        insert new MyOrgButler__c(SetupOwnerId = UserInfo.getUserId(), ThreadId__c = 't1', RunId__c = 'r1');

        Run run = new Run('t1', 'a1');
        run.id = 'r1';
        run.status = 'requires_action';
        run.required_action.type = 'submit_tool_outputs';
        run.required_action.submit_tool_outputs.tool_calls.add(new Run.ToolCall('callSalesforceApi', ''));

        new HttpMock()
                .post('aquiva_os__OpenAiApi/v1/threads/t1/messages').body(new Message('any')).statusCodeOk()
                .post('aquiva_os__OpenAiApi/v1/threads/t1/runs').body(run).statusCodeOk()
                .get('aquiva_os__OpenAiApi/v1/threads/t1/runs/r1').body(run).statusCodeOk()
                .get('/services/rest').body(300).statusCodeOk()
                .post('aquiva_os__OpenAiApi/v1/threads/t1/runs/r1/submit_tool_outputs').body(300).statusCodeOk()
                .get('aquiva_os__OpenAiApi/v1/threads/t1/runs/r1').body(run.status('completed')).statusCodeOk()
                .get('aquiva_os__OpenAiApi/v1/threads/t1/runs/r1/steps').body(new Run.Steps('completed')).statusCodeOk()
                .mock();

        // Exercise
        Test.startTest();
        new MyOrgButler().respond('Save the planet!');
        Test.stopTest();
        
        // Verify
        System.assertEquals('t1', MyOrgButler.callback.ThreadId__c);
    }

    @IsTest
    private static void modify() {
        // Setup
        insert new MyOrgButler__c(SetupOwnerId = UserInfo.getUserId(), ThreadId__c = 't1');  

        Message message = new Message();
        message.id = 'm1';

        Message.Metadata metadata = new Message.Metadata();
        metadata.isFeedbackPositive = 'true';
        message.metadata = metadata;

        new HttpMock()
                .post('aquiva_os__OpenAiApi/v1/threads/t1/messages/m1').body(message).statusCodeOk()
                .mock();

        // Exercise
        Test.startTest();
        message = new MyOrgButler().modify(message);
        Test.stopTest();

        // Verify
        System.assertEquals('true', message.metadata.isFeedbackPositive);
    }

    // HELPER

    @TestSetup
    private static void setup() {
        insert new MyOrgButler__c(SetupOwnerId = UserInfo.getOrganizationId(), ProdAssistantId__c = 'ignored', DevAssistantId__c = 'ignored');
    }
}