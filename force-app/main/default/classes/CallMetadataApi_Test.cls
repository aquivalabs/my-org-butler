@IsTest
private class CallMetadataApi_Test {
    
    @IsTest
    private static void happyPath() {

        // Setup
        Exception unexpectedException = null;
        mockResponse();

        CallMetadataApi.MetadataDescription metadata = new CallMetadataApi.MetadataDescription();
        metadata.soapAction = 'createMetadata';
        metadata.typeName = 'RemoteSiteSetting';
        metadata.attributesJson = '{ "fullName" : "Spiegel", "url" : "https://www.spiegel.de", "isActive" : true }';

        // Exercise
        try {
            List<CallMetadataApi.Output> result = CallMetadataApi.execute(new List<CallMetadataApi.MetadataDescription>{ metadata });
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

        CallMetadataApi.mockedResponse = response;
    }
}
