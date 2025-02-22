// PMD False Positives: 
public with sharing class RunSoqlQueries {

    @InvocableMethod(label='MyOrgButler: Run SOQL queries' description='Run arbitrary SOQL queries on org data and receive results as JSON')
    public static List<Output> execute(List<Input> input) {
        Output output = new Output();

        try {
            List<SObject> result = Database.query(input[0].dynamicSoqlQuery, AccessLevel.USER_MODE);
            output.queryResultAsJson = JSON.serialize(result);
        }
        catch(QueryException ex) {
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
        @InvocableVariable(label='Query Result as JSON' description='The result of the SOQL query converted to JSON' required=true)
        public String queryResultAsJson;

        @InvocableVariable(label='SOQL Error' description='Full message of an error or exception to learn and correct the query.' required=true)
        public String queryError;
    }
}