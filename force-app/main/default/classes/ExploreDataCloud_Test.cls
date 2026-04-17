@IsTest
private class ExploreDataCloud_Test {


    @IsTest
    private static void summary() {

        // Setup
        setup('{"metadata":[' +
            '{"name":"UnifiedIndividual__dlm","label":"Unified Individual","type":"DataModelObject","category":"Profile"},' +
            '{"name":"SalesOrder__dll","label":"Sales Order","type":"DataLakeObject","category":"Engagement"}' +
            ']}');

        ExploreDataCloud.Input input = new ExploreDataCloud.Input();
        input.scope = 'summary';


        // Exercise
        List<ExploreDataCloud.Output> result = ExploreDataCloud.execute(new List<ExploreDataCloud.Input>{ input });


        // Verify
        Map<String, Object> grouped = (Map<String, Object>) JSON.deserializeUntyped(result[0].response);
        Assert.isTrue(grouped.containsKey('DataModelObject'));
        Assert.isTrue(grouped.containsKey('DataLakeObject'));
    }


    @IsTest
    private static void details() {

        // Setup
        setup('{"metadata":[{' +
            '"name":"UnifiedIndividual__dlm",' +
            '"label":"Unified Individual",' +
            '"category":"Profile",' +
            '"fields":[{"name":"FirstName__c","type":"VARCHAR"},{"name":"AccountId__c","type":"VARCHAR"}],' +
            '"relationships":[{"fromEntity":"UnifiedIndividual__dlm","fromField":"AccountId__c","toEntity":"Account__dlm","toField":"Id","cardinality":"MANY_TO_ONE"}],' +
            '"primaryKeys":["Id__c"]' +
            '}]}');

        ExploreDataCloud.Input input = new ExploreDataCloud.Input();
        input.scope = 'details';
        input.entityName = 'UnifiedIndividual__dlm';


        // Exercise
        List<ExploreDataCloud.Output> result = ExploreDataCloud.execute(new List<ExploreDataCloud.Input>{ input });


        // Verify
        Map<String, Object> entity = (Map<String, Object>) JSON.deserializeUntyped(result[0].response);
        Assert.areEqual('UnifiedIndividual__dlm', entity.get('name'));
        Assert.isTrue(entity.containsKey('fields'));
        Assert.isTrue(entity.containsKey('relationships'));
        Assert.isTrue(entity.containsKey('primaryKeys'));
    }


    @IsTest
    private static void relationships() {

        // Setup
        setup('{"metadata":[{' +
            '"name":"UnifiedIndividual__dlm",' +
            '"label":"Unified Individual",' +
            '"fields":[{"name":"FirstName__c","type":"VARCHAR"}],' +
            '"relationships":[{"fromEntity":"UnifiedIndividual__dlm","fromField":"AccountId__c","toEntity":"Account__dlm","toField":"Id","cardinality":"MANY_TO_ONE"}]' +
            '}]}');

        ExploreDataCloud.Input input = new ExploreDataCloud.Input();
        input.scope = 'relationships';
        input.entityName = 'UnifiedIndividual__dlm';


        // Exercise
        List<ExploreDataCloud.Output> result = ExploreDataCloud.execute(new List<ExploreDataCloud.Input>{ input });


        // Verify
        Map<String, Object> entity = (Map<String, Object>) JSON.deserializeUntyped(result[0].response);
        Assert.isTrue(entity.containsKey('relationships'));
        Assert.isFalse(entity.containsKey('fields'));
    }


    @IsTest
    private static void requiresEntityName() {

        // Setup
        setup('{}');

        ExploreDataCloud.Input input = new ExploreDataCloud.Input();
        input.scope = 'details';


        // Exercise
        List<ExploreDataCloud.Output> result = ExploreDataCloud.execute(new List<ExploreDataCloud.Input>{ input });


        // Verify
        Map<String, Object> exceptionResult = (Map<String, Object>) JSON.deserializeUntyped(result[0].response);
        Assert.isTrue(((String) exceptionResult.get('message')).contains('entityName is required'));
    }


    @IsTest
    private static void exposesApiError() {

        // Setup
        HttpResponse response = new HttpResponse();
        response.setStatusCode(401);
        response.setBody('{"error":"Unauthorized"}');
        ExploreDataCloud.mockedResponse = response;

        ExploreDataCloud.Input input = new ExploreDataCloud.Input();
        input.scope = 'summary';


        // Exercise
        List<ExploreDataCloud.Output> result = ExploreDataCloud.execute(new List<ExploreDataCloud.Input>{ input });


        // Verify
        Map<String, Object> exceptionResult = (Map<String, Object>) JSON.deserializeUntyped(result[0].response);
        Assert.isTrue(((String) exceptionResult.get('message')).contains('401'));
    }


    // HELPER

    private static void setup(String body) {
        HttpResponse response = new HttpResponse();
        response.setStatusCode(200);
        response.setBody(body);
        ExploreDataCloud.mockedResponse = response;
    }
}
