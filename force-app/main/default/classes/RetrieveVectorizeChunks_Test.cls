@IsTest
private class RetrieveVectorizeChunks_Test {

    @TestSetup
    static void setup() {
        CustomSettings.mock('VectorizeOrgId', 'ORG');
        CustomSettings.mock('VectorizePipelineId', 'PIPELINE');
    }

    @IsTest
    private static void execute() {

        // Setup 
        new HttpMock()
            .post('/v1/org/ORG/pipelines/PIPELINE/retrieval')
            .body('{"documents": []}')
            .mock();

        RetrieveVectorizeChunks.Question question = new RetrieveVectorizeChunks.Question('What is the company policy?');

        // Exercise
        Test.startTest();
        List<RetrieveVectorizeChunks.Answer> results = RetrieveVectorizeChunks.execute(new List<RetrieveVectorizeChunks.Question>{ question });
        Test.stopTest();

        // Verify
        Assert.areEqual(1, results.size());
        Assert.isNotNull(results[0].content);
        Assert.isTrue(results[0].content.contains('Mock answer for testing'));
    }

    @IsTest
    private static void apiError() {

        // Setup
        ApplicationException expectedException = null;

        new HttpMock()
            .post('/v1/org/ORG/pipelines/PIPELINE/retrieval')
            .statusCode(500)
            .body('Internal Server Error')
            .mock();

        RetrieveVectorizeChunks.Question question = new RetrieveVectorizeChunks.Question('What is the company policy?');

        // Exercise 
        Test.startTest();
        try {
            RetrieveVectorizeChunks.execute(new List<RetrieveVectorizeChunks.Question>{ question });
        } 
        catch(ApplicationException ex) {
            expectedException = ex;
        }
        Test.stopTest();


        // Verify
        Assert.isNotNull(expectedException);
    }
}
