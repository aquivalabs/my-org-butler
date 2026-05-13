@IsTest
private class CheckHealth_Test {


    @IsTest
    private static void execute() {

        // Setup
        new HttpMock()
                .post('/search').statusCodeOk()
                .post('/ssot/query-sql').statusCodeOk()
                .mock();


        // Exercise
        List<CheckHealth.Output> result = CheckHealth.execute();


        // Verify
        Assert.isTrue(result[0].report.contains('Tavily (Web Search): OK'));
        Assert.isTrue(result[0].report.contains('Data Cloud: OK'));
    }


    @IsTest
    private static void reportsTavilyFailure() {

        // Setup
        new HttpMock()
                .post('/search').statusCodeUnauthorized()
                .post('/ssot/query-sql').statusCodeOk()
                .mock();


        // Exercise
        List<CheckHealth.Output> result = CheckHealth.execute();


        // Verify
        Assert.isTrue(result[0].report.contains('Tavily (Web Search): FAIL'));
    }


    @IsTest
    private static void reportsDataCloudFailure() {

        // Setup
        new HttpMock()
                .post('/search').statusCodeOk()
                .post('/ssot/query-sql').statusCodeInternalServerError()
                .mock();


        // Exercise
        List<CheckHealth.Output> result = CheckHealth.execute();


        // Verify
        Assert.isTrue(result[0].report.contains('Data Cloud: FAIL'));
    }
}
