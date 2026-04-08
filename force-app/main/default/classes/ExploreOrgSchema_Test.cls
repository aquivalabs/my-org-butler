@IsTest
private class ExploreOrgSchema_Test {

    private static final Boolean HAS_NAMESPACE = CustomSettings.class.getName().contains('.');
    private static final String MEMORY_API_NAME = HAS_NAMESPACE ? 'aquiva_os__Memory__c' : 'Memory__c';

    @IsTest
    private static void summary() {

        // Setup
        mockResponse();

        ExploreOrgSchema.Input input = new ExploreOrgSchema.Input();
        input.scope = 'summary';

        // Exercise
        List<ExploreOrgSchema.Output> result = ExploreOrgSchema.execute(new List<ExploreOrgSchema.Input>{ input });

        // Verify
        Assert.areEqual(1, result.size());
        String response = result[0].response;
        Assert.isTrue(response.contains(MEMORY_API_NAME));
        Assert.isTrue(response.contains('MyOrgButler Memory'));
    }


    @IsTest
    private static void summaryWithNamespaceFilter() {

        // Setup
        mockResponse();

        ExploreOrgSchema.Input input = new ExploreOrgSchema.Input();
        input.scope = 'summary';
        // Note: namespace filter only works in namespaced orgs — in namespaceless orgs we skip the filter
        if(HAS_NAMESPACE) {
            input.namespaceFilter = 'aquiva_os';
        }

        // Exercise
        List<ExploreOrgSchema.Output> result = ExploreOrgSchema.execute(new List<ExploreOrgSchema.Input>{ input });

        // Verify
        Assert.areEqual(1, result.size());
        String response = result[0].response;
        Assert.isTrue(response.contains(MEMORY_API_NAME));
    }


    @IsTest
    private static void details() {

        // Setup
        mockResponse();

        ExploreOrgSchema.Input input = new ExploreOrgSchema.Input();
        input.scope = 'details';
        input.objectFilter = MEMORY_API_NAME;

        // Exercise
        List<ExploreOrgSchema.Output> result = ExploreOrgSchema.execute(new List<ExploreOrgSchema.Input>{ input });

        // Verify
        Assert.areEqual(1, result.size());
        String response = result[0].response;
        Assert.isTrue(response.contains(MEMORY_API_NAME));
        Assert.isTrue(response.contains('MyOrgButler Memory'));
        Assert.isTrue(response.contains('Content__c'));
        Assert.isTrue(response.contains('Content'));
    }


    @IsTest
    private static void relationships() {

        // Setup
        mockResponse();

        ExploreOrgSchema.Input input = new ExploreOrgSchema.Input();
        input.scope = 'relationships';
        input.objectFilter = MEMORY_API_NAME;

        // Exercise
        List<ExploreOrgSchema.Output> result = ExploreOrgSchema.execute(new List<ExploreOrgSchema.Input>{ input });

        // Verify
        Assert.areEqual(1, result.size());
        String response = result[0].response;
        Assert.isTrue(response.contains(MEMORY_API_NAME));
        Assert.isTrue(response.contains('MyOrgButler Memory'));
        Assert.isTrue(response.contains('childRelationships'));
        Assert.isTrue(response.contains('parentRelationships'));
    }

    // HELPER

    private static void mockResponse() {
        HttpResponse response = new HttpResponse();
        response.setStatusCode(200);
        response.setBody('{"records":[{"DeveloperName":"' + MEMORY_API_NAME + '","Description":"MyOrgButler Memory"}]}');

        CallToolingApi.mockedResponse = response;
    }
}
