@IsTest
private class MyOrgButler_Test {
    
    @IsTest
    private static void initCreatesAndPersistsNewThread() {

        // Setup
        Thread t = new Thread().id('123');
        new HttpMock().post('aquiva_os__OpenAiApi/v1/threads', t).mock();

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
        insert new MyOrgButler__c(SetupOwnerId = UserInfo.getUserId(), ThreadId__c = '123', RunId__c = '987');
        
        new HttpMock()
                .post('aquiva_os__OpenAiApi/v1/threads/123/runs/987/cancel', true) 
                .del('aquiva_os__OpenAiApi/v1/threads/123', true)
                .post('aquiva_os__OpenAiApi/v1/threads', new Thread().id('999'))
                .mock();

        // Exercise
        // Note: without startTest "uncommited work error" due to Setting DML
        Test.startTest();
        new MyOrgButler().reset();
        Test.stopTest();

        // Verify
        MyOrgButler__c settings = MyOrgButler__c.getInstance(UserInfo.getUserId());
        System.assertNotEquals(null, settings);
        System.assertEquals('999', settings.ThreadId__c);
        System.assertEquals(null, settings.RunId__c);
    }

    
    @IsTest
    private static void messages() {

        // Setup
        insert new MyOrgButler__c(SetupOwnerId = UserInfo.getUserId(), ThreadId__c = '123');  

        Message.Messages messages = new Message.Messages();
        messages.data = new List<Message>{ new Message('Hi') };

        new HttpMock().get('aquiva_os__OpenAiApi/v1/threads/123/messages', messages).mock();

        // Exercise
        // Note: without startTest "uncommited work error" due to Setting DML
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
        insert new MyOrgButler__c(SetupOwnerId = UserInfo.getUserId(), ThreadId__c = '123');  

        Message m = new Message('Hi');
        m.run_id = '987';
        Message.Messages messages = new Message.Messages();
        messages.data = new List<Message>{ m };

        new HttpMock()
                .get('aquiva_os__OpenAiApi/v1/threads/123/runs/987/steps', new Run.Steps('completed'))
                .mock();

        // Exercise
        // Note: without startTest "uncommited work error" due to Setting DML
        Test.startTest();
        Run.Steps steps = new MyOrgButler().steps('987');
        Test.stopTest();
        
        // Verify
        System.assertEquals(1, steps.data.size());
        System.assertEquals('completed', steps.data[0].status);
    }

    
    @IsTest
    private static void respond() {

        // Setup
        insert new MyOrgButler__c(SetupOwnerId = UserInfo.getUserId(), ThreadId__c = '123', RunId__c = '987');

        Run run = new Run('123', 'abc');
        run.id = '987';
        run.status = 'requires_action';
        run.required_action.type = 'submit_tool_outputs';
        run.required_action.submit_tool_outputs.tool_calls.add(new Run.ToolCall('callSalesforceApi', ''));

        new HttpMock()
                .post('aquiva_os__OpenAiApi/v1/threads/123/messages', new Message('any'))
                .post('aquiva_os__OpenAiApi/v1/threads/123/runs', run)
                .get('aquiva_os__OpenAiApi/v1/threads/123/runs/987', run) // run calls tool
                .get('/services/rest', 300) // tool call
                .post('aquiva_os__OpenAiApi/v1/threads/123/runs/987/submit_tool_outputs', 300) // delegate back
                .get('aquiva_os__OpenAiApi/v1/threads/123/runs/987', run.status('completed'))
                .get('aquiva_os__OpenAiApi/v1/threads/123/runs/987/steps', new Run.Steps('completed')) 
                .mock();

        // Exercise
        Test.startTest();
        //System.enqueueJob(new MyOrgButler());
        new MyOrgButler().respond('Save the planet!', '42');
        Test.stopTest();
        
        // Verify
        System.assertEquals('123', MyOrgButler.callback.ThreadId__c);
    }

    
    @IsTest
    private static void modify() {

         // Setup
        insert new MyOrgButler__c(SetupOwnerId = UserInfo.getUserId(), ThreadId__c = '123');  

        Message message = new Message();
        message.id = '987';

        Message.Metadata metadata = new Message.Metadata();
        metadata.isFeedbackPositive = 'true';
        message.metadata = metadata;

        new HttpMock()
                .post('aquiva_os__OpenAiApi/v1/threads/123/messages/987', message)
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