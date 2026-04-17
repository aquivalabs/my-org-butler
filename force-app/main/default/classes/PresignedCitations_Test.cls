@IsTest
private class PresignedCitations_Test {


    @IsTest
    private static void extractsUrlAndFileName() {

        // Setup
        String responseBody = '{"data":[["https://signed.example.com/abc123?token=xyz","1JDRK000005/policy.pdf"]],"metadata":[]}';


        // Exercise
        List<PresignedCitations.Citation> result = new PresignedCitations('ADL_MyOrgButlerLibr_chunk__dlm')
            .extract(responseBody);


        // Verify
        Assert.areEqual(1, result.size());
        Assert.areEqual('https://signed.example.com/abc123?token=xyz', result[0].url);
        Assert.areEqual('policy.pdf', result[0].fileName);
    }
}
