@IsTest
private class QueryDataCloud_Test {

    @IsTest
    private static void execute() {

        // Setup - mock the serialized query result
        List<Map<String, Object>> mockData = new List<Map<String, Object>>{
            new Map<String, Object>{
                'ssot__Name__c' => 'Acme Renewal',
                'ssot__CloseDate__c' => '2026-03-15'
            },
            new Map<String, Object>{
                'ssot__Name__c' => 'TechCo Platform',
                'ssot__CloseDate__c' => '2026-03-28'
            }
        };
        QueryDataCloud.mockedQueryResult = JSON.serialize(mockData);

        // Exercise
        QueryDataCloud.Input input = new QueryDataCloud.Input();
        input.sqlQuery = 'SELECT ssot__Name__c, ssot__CloseDate__c FROM ssot__Opportunity__dlm LIMIT 10';

        List<QueryDataCloud.Output> result = QueryDataCloud.execute(
            new List<QueryDataCloud.Input>{ input }
        );

        // Verify
        Assert.areEqual(1, result.size());
        Assert.isTrue(String.isNotBlank(result[0].resultOrException));

        List<Object> records = (List<Object>) JSON.deserializeUntyped(result[0].resultOrException);
        Assert.areEqual(2, records.size());

        Map<String, Object> firstRecord = (Map<String, Object>) records[0];
        Assert.areEqual('Acme Renewal', firstRecord.get('ssot__Name__c'));
    }

    @IsTest
    private static void handleQueryError() {

        // Setup - no mock, CdpQuery will throw in test context
        QueryDataCloud.mockedQueryResult = null;

        // Exercise
        QueryDataCloud.Input input = new QueryDataCloud.Input();
        input.sqlQuery = 'SELECT invalid FROM ssot__Opportunity__dlm';

        List<QueryDataCloud.Output> result = QueryDataCloud.execute(
            new List<QueryDataCloud.Input>{ input }
        );

        // Verify - should return exception JSON
        Assert.areEqual(1, result.size());
        Assert.isTrue(String.isNotBlank(result[0].resultOrException));

        Map<String, Object> exceptionResult = (Map<String, Object>) JSON.deserializeUntyped(result[0].resultOrException);
        Assert.isTrue(exceptionResult.containsKey('message'));
        Assert.isTrue(exceptionResult.containsKey('typeName'));
    }
}
