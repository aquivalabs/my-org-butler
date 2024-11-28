@IsTest
private class UseMetadataApiTool_Test {
    
    @IsTest
    private static void happyPath() {

        // Setup
        Test.setMock(HttpCalloutMock.class, new MyHttpCalloutMock());
        Exception unexpectedException = null;


        // Exercise
        try {
            new UseMetadataApiTool().execute('{ "typeName" : "RemoteSiteSetting", "attributesJson" : "{ \\\"fullName\\\" : \\\"Spiegel\\\", \\\"url\\\" : \\\"https://www.spiegel.de\\\", \\\"isActive\\\" : true }"}');
        }
        catch(Exception ex) {
            unexpectedException = ex;
        }


        // Verify
        System.assertEquals(null, unexpectedException);
    }

    // INNER

    private class MyHttpCalloutMock implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest request) {
            HttpResponse result = new HttpResponse();
            result.setStatusCode(200);
            result.setBody('asdf');
            return result;
        }
    }
}