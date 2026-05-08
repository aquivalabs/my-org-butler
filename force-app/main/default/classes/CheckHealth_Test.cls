@IsTest
private class CheckHealth_Test {


    @IsTest
    private static void execute() {

        // Setup
        new HttpMock()
                .get('/services/data/').statusCodeOk()
                .post('/search').statusCodeOk()
                .post('/ssot/query-sql').statusCodeOk()
                .mock();


        // Exercise
        List<CheckHealth.Output> result = CheckHealth.execute();


        // Verify
        Assert.isTrue(result[0].report.contains('Salesforce REST API: OK'));
        Assert.isTrue(result[0].report.contains('Tavily (Web Search): OK'));
        Assert.isTrue(result[0].report.contains('Data Cloud: OK'));
    }


    @IsTest
    private static void reportsRestApiFailure() {

        // Setup
        new HttpMock()
                .get('/services/data/').statusCode(500)
                .post('/search').statusCodeOk()
                .post('/ssot/query-sql').statusCodeOk()
                .mock();


        // Exercise
        List<CheckHealth.Output> result = CheckHealth.execute();


        // Verify
        Assert.isTrue(result[0].report.contains('Salesforce REST API: HTTP 500'));
    }


    @IsTest
    private static void reportsTavilyFailure() {

        // Setup
        new HttpMock()
                .get('/services/data/').statusCodeOk()
                .post('/search').statusCodeUnauthorized()
                .post('/ssot/query-sql').statusCodeOk()
                .mock();


        // Exercise
        List<CheckHealth.Output> result = CheckHealth.execute();


        // Verify
        Assert.isTrue(result[0].report.contains('Tavily (Web Search): HTTP 401'));
    }


    @IsTest
    private static void reportsDataCloudFailure() {

        // Setup
        new HttpMock()
                .get('/services/data/').statusCodeOk()
                .post('/search').statusCodeOk()
                .post('/ssot/query-sql').statusCodeInternalServerError()
                .mock();


        // Exercise
        List<CheckHealth.Output> result = CheckHealth.execute();


        // Verify
        Assert.isTrue(result[0].report.contains('Data Cloud: HTTP 500'));
    }
}
