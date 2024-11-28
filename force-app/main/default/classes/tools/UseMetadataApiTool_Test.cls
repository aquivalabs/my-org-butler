@IsTest
private class UseMetadataApiTool_Test {
    
    @IsTest
    private static void happyPath() {

        // Setup
        Exception unexpectedException = null;
        mockResponse();

        // Exercise
        try {
            new UseMetadataApiTool().execute('{ "soapAction" : "createMetadata", "typeName" : "RemoteSiteSetting", "attributesJson" : "{ \\\"fullName\\\" : \\\"Spiegel\\\", \\\"url\\\" : \\\"https://www.spiegel.de\\\", \\\"isActive\\\" : true }"}');
        }
        catch(Exception ex) {
            unexpectedException = ex;
        }


        // Verify
        System.assertEquals(null, unexpectedException);
    }

    // HELPER

    private static void mockResponse() {
        HttpResponse response = new HttpResponse();
        response.setStatusCode(200);
        response.setBody('asdf');

        UseMetadataApi.mockedResponse = response;
    }
}