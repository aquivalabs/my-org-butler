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
        System.assertEquals(a, result[0].resultRecords[0]);
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
        System.assert(String.isNotBlank(output.queryError), 'Should contain error message');
        System.assert(output.queryError.contains('InvalidField'), 'Error should mention the invalid field');
    }
}
