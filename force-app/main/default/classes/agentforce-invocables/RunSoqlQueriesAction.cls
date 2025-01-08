// PMD False Positives: 
public with sharing class RunSoqlQueriesAction {

    @InvocableMethod(label='My Org Butler: Query Data Via SOQL' description='Run arbitrary SOQL queries on org data and receive results as JSON')
    public  static List<Output> execute(List<Input> input) {
        List<SObject> result = Database.query(input[0].dynamicSoqlQuery, AccessLevel.USER_MODE);

        Output output =  new Output();
        output.queryResultAsJson = JSON.serialize(result);
        return new List<Output>{ output };
    }

    // INNER

    public  class Input {
        @InvocableVariable(label='SOQL Query' description='Query to be executed as Dynamic SOQL' required=true)
        public  String dynamicSoqlQuery;
    }

    public  class Output {
        @InvocableVariable(label='Query Result as JSON' description='The result of the SOQL query converted to JSON' required=true)
        public  String queryResultAsJson;
    }
}