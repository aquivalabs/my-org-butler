@IsTest
public with sharing class RunSoqlQueries_Test {
  

    @IsTest
    static void execute() {

        // Setup
        insert new Account(Name='AcmeCorp');

        // Exercise
        RunSoqlQueries.Input input = new RunSoqlQueries.Input();
        input.dynamicSoqlQuery = 'SELECT Name FROM Account';

        List<RunSoqlQueries.Output> result = RunSoqlQueries.execute(
            new List<RunSoqlQueries.Input>{ input }
        );

        // Verify
        System.assertEquals(1, result.size());
        RunSoqlQueries.Output output = result[0];
        System.assert(output.queryResultAsJson.contains('AcmeCorp'));
    }

    @IsTest
    static void handleQueryError() {
        // Setup & Exercise
        RunSoqlQueries.Input input = new RunSoqlQueries.Input();
        input.dynamicSoqlQuery = 'SELECT InvalidField FROM Account';

        List<RunSoqlQueries.Output> result = RunSoqlQueries.execute(
            new List<RunSoqlQueries.Input>{ input }
        );

        // Verify
        System.assertEquals(1, result.size());
        RunSoqlQueries.Output output = result[0];
        System.assert(String.isNotBlank(output.queryError), 'Should contain error message');
        System.assert(output.queryError.contains('InvalidField'), 'Error should mention the invalid field');
    }
}
