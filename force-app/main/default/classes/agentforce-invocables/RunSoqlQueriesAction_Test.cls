@IsTest
public with sharing class RunSoqlQueriesAction_Test {
  

    @IsTest
    static void execute() {

        // Setup
        insert new Account(Name='AcmeCorp');

        // Exercise
        RunSoqlQueriesAction.Input input = new RunSoqlQueriesAction.Input();
        input.dynamicSoqlQuery = 'SELECT Name FROM Account';

        List<RunSoqlQueriesAction.Output> result = RunSoqlQueriesAction.execute(
            new List<RunSoqlQueriesAction.Input>{ input }
        );

        // Verify
        System.assertEquals(1, result.size());
        RunSoqlQueriesAction.Output output = result[0];
        System.assert(output.queryResultAsJson.contains('AcmeCorp'));
    }
}
