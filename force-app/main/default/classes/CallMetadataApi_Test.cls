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
            CallMetadataApi.execute(new List<CallMetadataApi.MetadataDescription>{ metadata });
        }
        catch(Exception ex) {
            unexpectedException = ex;
        }


        // Verify
        Assert.isNull(unexpectedException);
    }

    @IsTest
    private static void listMetadataWithFolder() {

        // Setup
        CallMetadataApi.MetadataDescription metadata = new CallMetadataApi.MetadataDescription();
        metadata.soapAction = 'listMetadata';
        metadata.typeName = 'Report';
        metadata.folder = 'unfiled$public';


        // Exercise
        String soapBody = CallMetadataApi.actionFor(metadata).setupRequest().getRequest().getBody();


        // Verify
        Assert.isTrue(soapBody.contains('unfiled$public'));
    }


    // HELPER

    private static void mockResponse() {
        HttpResponse response = new HttpResponse();
        response.setStatusCode(200);
        response.setBody('asdf');

        CallMetadataApi.mockedResponse = response;
    }
}
