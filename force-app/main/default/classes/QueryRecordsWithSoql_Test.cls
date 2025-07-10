@IsTest
public with sharing class QueryRecordsWithSoql_Test {
  

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
        System.assertEquals(1, result.size());
        System.assert(String.isNotBlank(result[0].resultOrException), 'Should contain JSON result');
        
        // Parse JSON to verify structure
        List<Object> records = (List<Object>) JSON.deserializeUntyped(result[0].resultOrException);
        System.assertEquals(1, records.size(), 'Should contain one record');
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
        System.assertEquals(1, result.size());
        QueryRecordsWithSoql.Output output = result[0];
        System.assert(String.isNotBlank(output.resultOrException), 'Should contain JSON result');
        
        // Parse JSON to verify exception structure
        Map<String, Object> exceptionResult = (Map<String, Object>) JSON.deserializeUntyped(output.resultOrException);
        System.assert(exceptionResult.containsKey('message'), 'Should contain message key');
        System.assert(exceptionResult.containsKey('typeName'), 'Should contain typeName key');
        System.assert(((String)exceptionResult.get('message')).contains('InvalidField'), 'Error should mention the invalid field');
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
        System.assertEquals(1, result.size());
        System.assert(String.isNotBlank(result[0].resultOrException), 'Should contain JSON result');
        
        // Parse JSON to verify aggregate structure
        List<Object> aggregateResults = (List<Object>) JSON.deserializeUntyped(result[0].resultOrException);
        System.assertEquals(1, aggregateResults.size(), 'Should contain one aggregate result');
        
        Map<String, Object> firstResult = (Map<String, Object>) aggregateResults[0];
        System.assert(firstResult.containsKey('Type'), 'Should contain Type field');
        System.assert(firstResult.containsKey('recordCount'), 'Should contain count field');
    }
}
