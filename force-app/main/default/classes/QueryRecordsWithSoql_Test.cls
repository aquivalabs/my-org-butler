@IsTest
private class QueryRecordsWithSoql_Test {
  

    @IsTest
    static void execute() {

        // Setup
        Account a = new Account(Name='AcmeCorp');
        insert a;

        // Exercise
        QueryRecordsWithSoql.Input input = new QueryRecordsWithSoql.Input();
        input.dynamicSoqlQuery = 'SELECT Name FROM Account';

        List<QueryRecordsWithSoql.Output> result = QueryRecordsWithSoql.execute(
            new List<QueryRecordsWithSoql.Input>{ input }
        );

        // Verify
        Assert.areEqual(1, result.size());
        Assert.isTrue(String.isNotBlank(result[0].resultOrException));
        
        List<Object> records = (List<Object>) JSON.deserializeUntyped(result[0].resultOrException);
        Assert.areEqual(1, records.size());
    }

    @IsTest
    static void handleQueryError() {
        // Setup & Exercise
        QueryRecordsWithSoql.Input input = new QueryRecordsWithSoql.Input();
        input.dynamicSoqlQuery = 'SELECT InvalidField FROM Account';

        List<QueryRecordsWithSoql.Output> result = QueryRecordsWithSoql.execute(
            new List<QueryRecordsWithSoql.Input>{ input }
        );

        // Verify
        Assert.areEqual(1, result.size());
        QueryRecordsWithSoql.Output output = result[0];
        Assert.isTrue(String.isNotBlank(output.resultOrException));
        
        Map<String, Object> exceptionResult = (Map<String, Object>) JSON.deserializeUntyped(output.resultOrException);
        Assert.isTrue(exceptionResult.containsKey('message'));
        Assert.isTrue(exceptionResult.containsKey('typeName'));
        Assert.isTrue(((String)exceptionResult.get('message')).contains('InvalidField'));
    }
    
    @IsTest
    static void executeAggregateQuery() {
        // Setup
        Account a1 = new Account(Name='AcmeCorp', Type='Customer');
        Account a2 = new Account(Name='GlobalCorp', Type='Customer');
        insert new List<Account>{ a1, a2 };

        // Exercise - Aggregate query with GROUP BY
        QueryRecordsWithSoql.Input input = new QueryRecordsWithSoql.Input();
        input.dynamicSoqlQuery = 'SELECT Type, COUNT(Id) recordCount FROM Account GROUP BY Type';

        List<QueryRecordsWithSoql.Output> result = QueryRecordsWithSoql.execute(
            new List<QueryRecordsWithSoql.Input>{ input }
        );

        // Verify
        Assert.areEqual(1, result.size());
        Assert.isTrue(String.isNotBlank(result[0].resultOrException));
        
        List<Object> aggregateResults = (List<Object>) JSON.deserializeUntyped(result[0].resultOrException);
        Assert.areEqual(1, aggregateResults.size());
        
        Map<String, Object> firstResult = (Map<String, Object>) aggregateResults[0];
        Assert.isTrue(firstResult.containsKey('Type'));
        Assert.isTrue(firstResult.containsKey('recordCount'));
    }
}
