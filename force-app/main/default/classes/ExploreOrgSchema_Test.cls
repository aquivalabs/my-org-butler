@IsTest
private class ExploreOrgSchema_Test {

    @IsTest
    private static void summary() {

        // Setup
        mockResponse();

        ExploreOrgSchema.Input input = new ExploreOrgSchema.Input();
        input.scope = 'summary';

        // Exercise
        List<ExploreOrgSchema.Output> result = ExploreOrgSchema.execute(new List<ExploreOrgSchema.Input>{ input });

        // Verify
        System.assertEquals(1, result.size());
        String response = result[0].response;
        System.assert(response.contains('aquiva_os__Memory__c'), response);
        System.assert(response.contains('MyOrgButler Memory'), response);
    }

    @IsTest
    private static void summaryWithNamespaceFilter() {
        
        // Setup
        mockResponse();

        ExploreOrgSchema.Input input = new ExploreOrgSchema.Input();
        input.scope = 'summary';
        input.namespaceFilter = 'aquiva_os';

        // Exercise
        List<ExploreOrgSchema.Output> result = ExploreOrgSchema.execute(new List<ExploreOrgSchema.Input>{ input });

        // Verify
        System.assertEquals(1, result.size());
        String response = result[0].response;
        System.assert(response.contains('aquiva_os__Memory__c'), response);
        System.assert(response.contains('MyOrgButler Memory'), response);
    }


    @IsTest
    private static void details() {

        // Setup
        mockResponse();

        ExploreOrgSchema.Input input = new ExploreOrgSchema.Input();
        input.scope = 'details';
        input.objectFilter = 'aquiva_os__Memory__c';

        // Exercise
        List<ExploreOrgSchema.Output> result = ExploreOrgSchema.execute(new List<ExploreOrgSchema.Input>{ input });

        // Verify
        System.assertEquals(1, result.size());
        String response = result[0].response;
        System.assert(response.contains('aquiva_os__Memory__c'), response);
        System.assert(response.contains('MyOrgButler Memory'), response);
        System.assert(response.contains('Content__c'), response);
        System.assert(response.contains('Content'), response);
    }

    @IsTest
    private static void relationships() {

        // Setup
        mockResponse();

        ExploreOrgSchema.Input input = new ExploreOrgSchema.Input();
        input.scope = 'relationships';
        input.objectFilter = 'aquiva_os__Memory__c';

        // Exercise
        List<ExploreOrgSchema.Output> result = ExploreOrgSchema.execute(new List<ExploreOrgSchema.Input>{ input });

        // Verify
        System.assertEquals(1, result.size());
        String response = result[0].response;
        System.assert(response.contains('aquiva_os__Memory__c'), response);
        System.assert(response.contains('MyOrgButler Memory'), response);
        // Even if no custom relationships exist, the response should contain relationship arrays
        System.assert(response.contains('childRelationships'), response);
        System.assert(response.contains('parentRelationships'), response);
    }

    // HELPER

    private static void mockResponse() {
        HttpResponse response = new HttpResponse();
        response.setStatusCode(200);
        response.setBody('{"records":[{"DeveloperName":"aquiva_os__Memory__c","Description":"MyOrgButler Memory"}]}');
        
        CallToolingApi.mockedResponse = response;
    }
} 