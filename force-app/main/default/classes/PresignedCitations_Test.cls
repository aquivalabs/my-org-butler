@IsTest
private class PresignedCitations_Test {


    @IsTest
    private static void buildsCitationWithUrlAndFileName() {

        // Setup
        DataCloudSql.mockedResponse = '{"data":[["https://presigned.example.com/policy.pdf?token=abc","1JDRK000005/policy.pdf"]],"metadata":[]}';

        // Exercise
        AiCopilot.GenAiCitationInput result = new PresignedCitations('ADL_MyOrgButlerLibr_chunk__dlm')
            .forDocuments(new Set<String>{ '1JDRK000005/policy.pdf' });

        // Verify
        String json = JSON.serialize(result);
        Assert.isTrue(json.contains('https://presigned.example.com/policy.pdf?token=abc'));
        Assert.isTrue(json.contains('policy.pdf'));
    }
}
