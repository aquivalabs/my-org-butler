@IsTest
private class CheckHealth_Test {

    @IsTest
    private static void allProbesHealthy() {

        // Setup
        new HttpMock()
                .get('/services/data/v66.0/').body('[{"version":"66.0"}]').statusCodeOk()
                .get('/services/data/v66.0/ssot/metadata').body('{"metadata":[]}').statusCodeOk()
                .post('/search').body('{"answer":"ok"}').statusCodeOk()
                .mock();

        // Exercise
        Test.startTest();
        List<CheckHealth.Output> results = CheckHealth.execute(new List<String>{ null });
        Test.stopTest();

        // Verify
        Assert.areEqual(1, results.size());
        List<Object> probes = (List<Object>) JSON.deserializeUntyped(results[0].report);
        Assert.areEqual(5, probes.size());
        for (Object probe : probes) {
            Map<String, Object> p = (Map<String, Object>) probe;
            Assert.areEqual('ok', p.get('status'), 'Expected ok for probe: ' + p.get('name'));
        }
    }


    @IsTest
    private static void continuesWhenOneProbeErrors() {

        // Setup
        new HttpMock()
                .get('/services/data/v66.0/').statusCodeInternalServerError().body('{"error":"down"}')
                .get('/services/data/v66.0/ssot/metadata').body('{"metadata":[]}').statusCodeOk()
                .post('/search').body('{"answer":"ok"}').statusCodeOk()
                .mock();

        // Exercise
        Test.startTest();
        List<CheckHealth.Output> results = CheckHealth.execute(new List<String>{ null });
        Test.stopTest();

        // Verify
        List<Object> probes = (List<Object>) JSON.deserializeUntyped(results[0].report);
        Assert.areEqual(5, probes.size());

        Map<String, Object> restProbe = findProbe(probes, 'Salesforce REST API');
        Assert.areEqual('error', restProbe.get('status'));
        Assert.isTrue(((String) restProbe.get('detail')).contains('500'));

        Map<String, Object> dataCloudProbe = findProbe(probes, 'Data Cloud SSOT API');
        Assert.areEqual('ok', dataCloudProbe.get('status'));

        Map<String, Object> tavilyProbe = findProbe(probes, 'Named Credential: TavilyApi');
        Assert.areEqual('ok', tavilyProbe.get('status'));
    }


    // HELPER

    private static Map<String, Object> findProbe(List<Object> probes, String name) {
        for (Object probe : probes) {
            Map<String, Object> p = (Map<String, Object>) probe;
            if (name.equals(String.valueOf(p.get('name')))) {
                return p;
            }
        }
        return null;
    }
}
