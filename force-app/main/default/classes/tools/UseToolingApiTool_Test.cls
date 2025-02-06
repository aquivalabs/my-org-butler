@IsTest
private class UseToolingApiTool_Test {
    
    @IsTest
    private static void queryAction() {
        // Setup
        Exception unexpectedException = null;
        mockResponse('{"records":[{"Id":"01p....","Name":"TestClass"}]}');

        // Exercise
        try {
            new UseToolingApiTool().execute('{ "action" : "query", "soql" : "SELECT Id, Name FROM ApexClass"}');
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

        // Exercise
        try {
            new UseToolingApiTool().execute('{ "action" : "create", "objectType" : "ApexClass", "recordJson" : "{ \\"Name\\" : \\"TestClass\\", \\"Body\\" : \\"public class TestClass {}\\" }"}');
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

        // Exercise
        try {
            new UseToolingApiTool().execute('{ "action" : "update", "objectType" : "ApexClass", "recordId" : "01p....", "recordJson" : "{ \\"Body\\" : \\"public class TestClass { }\\" }"}');
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

        // Exercise
        try {
            new UseToolingApiTool().execute('{ "action" : "delete", "objectType" : "ApexClass", "recordId" : "01p...."}');
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

        // Exercise
        try {
            new UseToolingApiTool().execute('{ "action" : "invalid" }');
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

        UseToolingApi.mockedResponse = response;
    }
}