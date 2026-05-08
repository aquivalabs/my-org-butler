@IsTest
private class CheckHealth_Test {

    @IsTest
    private static void allProbesOk() {

        // Setup
        mockToolingApi('{"records":[]}');
        DataCloudSql.mockedResponse = '{"data":[]}';
        CustomSettings.mock('TestSetting', 'val');
        insert as user new Memory__c(Name = 'health-test', Content__c = 'test', IsShared__c = false);
        new HttpMock()
                .get('/services/data/').body('[]').statusCodeOk()
                .post('/search').body('{"answer":"ok"}').statusCodeOk()
                .mock();

        // Exercise
        Test.startTest();
        List<CheckHealth.Output> results = CheckHealth.execute(new List<String>{ null });
        Test.stopTest();

        // Verify
        Assert.areEqual(1, results.size());
        String report = results[0].report;
        Assert.isTrue(report.contains('[OK] Salesforce REST API'), report);
        Assert.isTrue(report.contains('[OK] Tooling API'), report);
        Assert.isTrue(report.contains('[OK] Named Credential TavilyApi'), report);
        Assert.isTrue(report.contains('[OK] Data Cloud'), report);
        Assert.isTrue(report.contains('[OK] Memory Storage'), report);
        Assert.isTrue(report.contains('[OK] Custom Settings'), report);
    }


    @IsTest
    private static void restApiProbeReportsError() {

        // Setup
        mockToolingApi('{"records":[]}');
        DataCloudSql.mockedResponse = '{"data":[]}';
        new HttpMock()
                .get('/services/data/').body('Unauthorized').statusCodeUnauthorized()
                .post('/search').body('{"answer":"ok"}').statusCodeOk()
                .mock();

        // Exercise
        List<CheckHealth.Output> results = CheckHealth.execute(new List<String>{ null });

        // Verify
        String report = results[0].report;
        Assert.isTrue(report.contains('[ERROR] Salesforce REST API'), report);
        Assert.isTrue(report.contains('HTTP 401'), report);
    }


    @IsTest
    private static void tavilyProbeReportsError() {

        // Setup
        mockToolingApi('{"records":[]}');
        DataCloudSql.mockedResponse = '{"data":[]}';
        new HttpMock()
                .get('/services/data/').body('[]').statusCodeOk()
                .post('/search').body('Unauthorized').statusCodeUnauthorized()
                .mock();

        // Exercise
        List<CheckHealth.Output> results = CheckHealth.execute(new List<String>{ null });

        // Verify
        String report = results[0].report;
        Assert.isTrue(report.contains('[ERROR] Named Credential TavilyApi'), report);
        Assert.isTrue(report.contains('HTTP 401'), report);
    }


    @IsTest
    private static void dataCloudEndpointReachableOnQueryError() {

        // Setup
        mockToolingApi('{"records":[]}');
        DataCloudSql.mockedResponse = null;
        new HttpMock()
                .get('/services/data/').body('[]').statusCodeOk()
                .post('/search').body('{"answer":"ok"}').statusCodeOk()
                .post('/ssot/query-sql').body('[{"message":"Invalid SQL"}]').statusCodeBadRequest()
                .mock();

        // Exercise
        List<CheckHealth.Output> results = CheckHealth.execute(new List<String>{ null });

        // Verify
        String report = results[0].report;
        Assert.isTrue(report.contains('[OK] Data Cloud'), report);
        Assert.isTrue(report.contains('Endpoint reachable'), report);
    }


    @IsTest
    private static void reportIncludesMemoryAndSettingsCounts() {

        // Setup
        mockToolingApi('{"records":[]}');
        DataCloudSql.mockedResponse = '{"data":[]}';
        CustomSettings.mock('Key1', 'v1');
        CustomSettings.mock('Key2', 'v2');
        insert as user new List<Memory__c>{
            new Memory__c(Name = 'm1', Content__c = 'one', IsShared__c = false),
            new Memory__c(Name = 'm2', Content__c = 'two', IsShared__c = false)
        };
        new HttpMock()
                .get('/services/data/').body('[]').statusCodeOk()
                .post('/search').body('{"answer":"ok"}').statusCodeOk()
                .mock();

        // Exercise
        Test.startTest();
        List<CheckHealth.Output> results = CheckHealth.execute(new List<String>{ null });
        Test.stopTest();

        // Verify
        String report = results[0].report;
        Assert.isTrue(report.contains('[OK] Memory Storage'), report);
        Assert.isTrue(report.contains('[OK] Custom Settings'), report);
    }


    // HELPER

    private static void mockToolingApi(String body) {
        HttpResponse response = new HttpResponse();
        response.setStatusCode(200);
        response.setBody(body);
        CallToolingApi.mockedResponse = response;
    }
}
