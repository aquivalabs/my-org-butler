public with sharing class RunSoqlQueries {

    @InvocableMethod(label='MyOrgButler: Run SOQL Queries' description='Run a single SOQL Query and return a list of records or errors')
    public static List<Output> execute(List<Input> input) {
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

    public class Input {
        @InvocableVariable(label='SOQL Query' description='Query to be executed as Dynamic SOQL' required=true)
        public String dynamicSoqlQuery;
    }

    public class Output {
        @InvocableVariable(label='Result Records as List of SObjects' description='The result of the SOQL query as List of SObjects')
        public List<SObject> resultRecords;

        @InvocableVariable(label='SOQL Error' description='Full message of an error or exception to learn and correct the query.')
        public String queryError;
    }
}