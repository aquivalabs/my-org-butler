@IsTest
private class QueryDataCloud_Test {


    @IsTest
    private static void executesQueryAndTransformsColumnsToMaps() {

        // Setup
        setup(200, '{' +
            '"completionStatus":"COMPLETE",' +
            '"metadata":[{"name":"FirstName__c","type":"VARCHAR"},{"name":"LastName__c","type":"VARCHAR"}],' +
            '"data":[["Jane","Doe"],["John","Smith"]]' +
            '}');

        QueryDataCloud.Input input = new QueryDataCloud.Input();
        input.sqlQuery = 'SELECT FirstName__c, LastName__c FROM UnifiedIndividual__dlm LIMIT 2';


        // Exercise
        List<QueryDataCloud.Output> result = QueryDataCloud.execute(new List<QueryDataCloud.Input>{ input });


        // Verify
        List<Object> records = (List<Object>) JSON.deserializeUntyped(result[0].resultOrException);
        Assert.areEqual(2, records.size());

        Map<String, Object> firstRow = (Map<String, Object>) records[0];
        Assert.areEqual('Jane', firstRow.get('FirstName__c'));
        Assert.areEqual('Doe', firstRow.get('LastName__c'));
    }


    @IsTest
    private static void partialCompletionIncludesWarning() {

        // Setup
        setup(200, '{' +
            '"completionStatus":"PARTIAL",' +
            '"metadata":[{"name":"Name__c","type":"VARCHAR"}],' +
            '"data":[["Acme"]]' +
            '}');

        QueryDataCloud.Input input = new QueryDataCloud.Input();
        input.sqlQuery = 'SELECT Name__c FROM Account__dlm';


        // Exercise
        List<QueryDataCloud.Output> result = QueryDataCloud.execute(new List<QueryDataCloud.Input>{ input });


        // Verify
        Map<String, Object> envelope = (Map<String, Object>) JSON.deserializeUntyped(result[0].resultOrException);
        Assert.areEqual('PARTIAL', envelope.get('status'));
        Assert.isTrue(((List<Object>) envelope.get('data')).size() > 0);
    }


    @IsTest
    private static void wrapsHttpErrorAsException() {

        // Setup
        setup(400, '{"errorCode":"INVALID_SQL","message":"Syntax error at line 1"}');

        QueryDataCloud.Input input = new QueryDataCloud.Input();
        input.sqlQuery = 'SELECT * FORM UnifiedIndividual__dlm';


        // Exercise
        List<QueryDataCloud.Output> result = QueryDataCloud.execute(new List<QueryDataCloud.Input>{ input });


        // Verify
        Map<String, Object> exceptionResult = (Map<String, Object>) JSON.deserializeUntyped(result[0].resultOrException);
        Assert.isTrue(((String) exceptionResult.get('message')).contains('400'));
    }


    // HELPER

    private static void setup(Integer statusCode, String body) {
        HttpResponse response = new HttpResponse();
        response.setStatusCode(statusCode);
        response.setBody(body);
        QueryDataCloud.mockedResponse = response;
    }
}
