@IsTest
private class ExploreDataCloud_Test {


    @IsTest
    private static void summary() {

        // Setup
        enqueue('{"metadata":[' +
            '{"name":"UnifiedIndividual__dlm","label":"Unified Individual","type":"DataModelObject","category":"Profile"},' +
            '{"name":"SalesOrder__dll","label":"Sales Order","type":"DataLakeObject","category":"Engagement"}' +
            '],"nextPageUrl":"/services/data/v66.0/ssot/metadata?page=2"}');
        enqueue('{"metadata":[' +
            '{"name":"AiAgentInteractionStep__dlm","label":"Agent Interaction Step","type":"DataModelObject","category":"Related"}' +
            ']}');

        ExploreDataCloud.Input input = new ExploreDataCloud.Input();
        input.scope = 'summary';


        // Exercise
        List<ExploreDataCloud.Output> result = ExploreDataCloud.execute(new List<ExploreDataCloud.Input>{ input });


        // Verify
        Map<String, Object> root = (Map<String, Object>) JSON.deserializeUntyped(result[0].response);
        Map<String, Object> entities = (Map<String, Object>) root.get('entities');
        List<Object> dmos = (List<Object>) entities.get('DataModelObject');
        Assert.areEqual(2, dmos.size());
        Assert.isTrue(entities.containsKey('DataLakeObject'));
    }


    @IsTest
    private static void details() {

        // Setup
        enqueue('{"metadata":[{' +
            '"name":"AiAgentSession__dlm","label":"AI Agent Session","category":"Related",' +
            '"fields":[{"name":"Id__c","type":"VARCHAR"}],' +
            '"primaryKeys":["Id__c"]' +
            '}]}');
        enqueue('{"metadata":[{' +
            '"name":"AiAgentInteractionStep__dlm","label":"Agent Interaction Step","category":"Related",' +
            '"fields":[{"name":"StepType__c","type":"VARCHAR"}],' +
            '"relationships":[{"fromEntity":"AiAgentInteractionStep__dlm","toEntity":"AiAgentInteraction__dlm"}]' +
            '}]}');

        ExploreDataCloud.Input input = new ExploreDataCloud.Input();
        input.scope = 'details';
        input.entityName = 'AiAgentSession__dlm, AiAgentInteractionStep__dlm';


        // Exercise
        List<ExploreDataCloud.Output> result = ExploreDataCloud.execute(new List<ExploreDataCloud.Input>{ input });


        // Verify
        Map<String, Object> entities = (Map<String, Object>) JSON.deserializeUntyped(result[0].response);
        Assert.isTrue(entities.containsKey('AiAgentSession__dlm'));
        Assert.isTrue(entities.containsKey('AiAgentInteractionStep__dlm'));

        Map<String, Object> step = (Map<String, Object>) entities.get('AiAgentInteractionStep__dlm');
        Assert.isTrue(step.containsKey('fields'));
        Assert.isTrue(step.containsKey('relationships'));
    }


    @IsTest
    private static void relationships() {

        // Setup
        enqueue('{"metadata":[{' +
            '"name":"UnifiedIndividual__dlm","label":"Unified Individual",' +
            '"fields":[{"name":"FirstName__c","type":"VARCHAR"}],' +
            '"relationships":[{"fromEntity":"UnifiedIndividual__dlm","toEntity":"Account__dlm"}]' +
            '}]}');

        ExploreDataCloud.Input input = new ExploreDataCloud.Input();
        input.scope = 'relationships';
        input.entityName = 'UnifiedIndividual__dlm';


        // Exercise
        List<ExploreDataCloud.Output> result = ExploreDataCloud.execute(new List<ExploreDataCloud.Input>{ input });


        // Verify
        Map<String, Object> entities = (Map<String, Object>) JSON.deserializeUntyped(result[0].response);
        Map<String, Object> entity = (Map<String, Object>) entities.get('UnifiedIndividual__dlm');
        Assert.isTrue(entity.containsKey('relationships'));
        Assert.isFalse(entity.containsKey('fields'));
    }


    @IsTest
    private static void requiresEntityName() {

        // Setup
        enqueue('{}');

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
        ExploreDataCloud.mockedResponses.add(response);

        ExploreDataCloud.Input input = new ExploreDataCloud.Input();
        input.scope = 'summary';


        // Exercise
        List<ExploreDataCloud.Output> result = ExploreDataCloud.execute(new List<ExploreDataCloud.Input>{ input });


        // Verify
        Map<String, Object> exceptionResult = (Map<String, Object>) JSON.deserializeUntyped(result[0].response);
        Assert.isTrue(((String) exceptionResult.get('message')).contains('401'));
    }


    // HELPER

    private static void enqueue(String body) {
        HttpResponse response = new HttpResponse();
        response.setStatusCode(200);
        response.setBody(body);
        ExploreDataCloud.mockedResponses.add(response);
    }
}
