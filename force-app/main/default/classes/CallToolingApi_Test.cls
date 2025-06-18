@IsTest
private class CallToolingApi_Test {
    
    @IsTest
    private static void queryAction() {
        // Setup
        Exception unexpectedException = null;
        mockResponse('{"records":[{"Id":"01p....","Name":"TestClass"}]}');

        CallToolingApi.ToolingDescription tooling = new CallToolingApi.ToolingDescription();
        tooling.action = 'query';
        tooling.soql = 'SELECT Id, Name FROM ApexClass';

        // Exercise
        try {
            List<CallToolingApi.Output> result = CallToolingApi.execute(new List<CallToolingApi.ToolingDescription>{ tooling });
        }
        catch(Exception ex) {
            unexpectedException = ex;
        }

        // Verify
        System.assertEquals(null, unexpectedException);
    }

    @IsTest
    private static void createAction() {
        // Setup
        Exception unexpectedException = null;
        mockResponse('{"id":"01p....","success":true}');

        CallToolingApi.ToolingDescription tooling = new CallToolingApi.ToolingDescription();
        tooling.action = 'create';
        tooling.objectType = 'ApexClass';
        tooling.recordJson = '{ "Name" : "TestClass", "Body" : "public class TestClass {}" }';

        // Exercise
        try {
            List<CallToolingApi.Output> result = CallToolingApi.execute(new List<CallToolingApi.ToolingDescription>{ tooling });
        }
        catch(Exception ex) {
            unexpectedException = ex;
        }

        // Verify
        System.assertEquals(null, unexpectedException);
    }

    @IsTest
    private static void updateAction() {
        // Setup
        Exception unexpectedException = null;
        mockResponse('{"id":"01p....","success":true}');

        CallToolingApi.ToolingDescription tooling = new CallToolingApi.ToolingDescription();
        tooling.action = 'update';
        tooling.objectType = 'ApexClass';
        tooling.recordId = '01p....';
        tooling.recordJson = '{ "Body" : "public class TestClass { }" }';

        // Exercise
        try {
            List<CallToolingApi.Output> result = CallToolingApi.execute(new List<CallToolingApi.ToolingDescription>{ tooling });
        }
        catch(Exception ex) {
            unexpectedException = ex;
        }

        // Verify
        System.assertEquals(null, unexpectedException);
    }

    @IsTest
    private static void deleteAction() {
        // Setup
        Exception unexpectedException = null;
        mockResponse('');

        CallToolingApi.ToolingDescription tooling = new CallToolingApi.ToolingDescription();
        tooling.action = 'delete';
        tooling.objectType = 'ApexClass';
        tooling.recordId = '01p....';

        // Exercise
        try {
            List<CallToolingApi.Output> result = CallToolingApi.execute(new List<CallToolingApi.ToolingDescription>{ tooling });
        }
        catch(Exception ex) {
            unexpectedException = ex;
        }

        // Verify
        System.assertEquals(null, unexpectedException);
    }

    @IsTest
    private static void invalidAction() {
        // Setup
        Exception expectedException = null;

        CallToolingApi.ToolingDescription tooling = new CallToolingApi.ToolingDescription();
        tooling.action = 'invalid';

        // Exercise
        try {
            List<CallToolingApi.Output> result = CallToolingApi.execute(new List<CallToolingApi.ToolingDescription>{ tooling });
        }
        catch(Exception ex) {
            expectedException = ex;
        }

        // Verify
        System.assertNotEquals(null, expectedException);
        System.assert(expectedException.getMessage().contains('Unsupported Tooling API action'));
    }

    // HELPER

    private static void mockResponse(String body) {
        HttpResponse response = new HttpResponse();
        response.setStatusCode(200);
        response.setBody(body);

        CallToolingApi.mockedResponse = response;
    }
}
