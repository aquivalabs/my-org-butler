@IsTest
private class ExploreDataCloud_Test {


    @IsTest
    private static void summaryReturnsEntitiesGroupedByType() {

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
        Assert.isTrue(result[0].response.contains('UnifiedIndividual__dlm'));
        Assert.isTrue(result[0].response.contains('SalesOrder__dll'));
    }


    @IsTest
    private static void detailsReturnsFieldsAndRelationships() {

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
        Assert.isTrue(result[0].response.contains('FirstName__c'));
        Assert.isTrue(result[0].response.contains('AccountId__c'));
        Assert.isTrue(result[0].response.contains('Account__dlm'));
        Assert.isTrue(result[0].response.contains('MANY_TO_ONE'));
        Assert.isTrue(result[0].response.contains('Id__c'));
    }


    @IsTest
    private static void relationshipsReturnsOnlyRelationships() {

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
        Assert.isTrue(result[0].response.contains('Account__dlm'));
        Assert.isFalse(result[0].response.contains('FirstName__c'));
    }


    @IsTest
    private static void wrapsApiErrorAsException() {

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
        Assert.isTrue(exceptionResult.containsKey('message'));
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
