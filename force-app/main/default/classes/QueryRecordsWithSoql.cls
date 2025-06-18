// PMD False Positives: Agentforce requires Global
@SuppressWarnings('PMD.AvoidGlobalMethod')
global with sharing class QueryRecordsWithSoql {

    @InvocableMethod(label='MyOrgButler: Run SOQL Queries' description='Run a single SOQL Query and return a list of records or errors')
    global static List<Output> execute(List<Input> input) {
        Output output = new Output();

        try {
            List<SObject> result = Database.query(input[0].dynamicSoqlQuery, AccessLevel.USER_MODE);
            output.resultRecords = result;
        }
        catch(Exception ex) {
            output.queryError = ex.getMessage();
        }

        return new List<Output>{ output };
    }

    // INNER

    global class Input {
        @InvocableVariable(label='SOQL Query' description='Query to be executed as Dynamic SOQL' required=true)
        global String dynamicSoqlQuery;
    }

    global class Output {
        @InvocableVariable(label='Result Records as List of SObjects' description='The result of the SOQL query as List of SObjects')
        global List<SObject> resultRecords;

        @InvocableVariable(label='SOQL Error' description='Full message of an error or exception to learn and correct the query.')
        global String queryError;
    }
}