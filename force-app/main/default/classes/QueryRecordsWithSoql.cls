// PMD False Positives: Agentforce requires Global
@SuppressWarnings('PMD.AvoidGlobalMethod')
global with sharing class QueryRecordsWithSoql {

    @InvocableMethod(label='MyOrgButler: Run SOQL Queries' description='Run a single SOQL Query and return a list of records or errors')
    global static List<Output> execute(List<Input> input) {
        Output output = new Output();

        try {
            List<Object> result = Database.query(input[0].dynamicSoqlQuery, AccessLevel.USER_MODE);
            output.resultOrException = JSON.serialize(result);
        }
        catch(Exception ex) {
            // Create a serializable exception representation
            Map<String, Object> exceptionInfo = new Map<String, Object>{
                'message' => ex.getMessage(),
                'typeName' => ex.getTypeName(),
                'stackTrace' => ex.getStackTraceString()
            };
            output.resultOrException = JSON.serialize(exceptionInfo);
        }

        return new List<Output>{ output };
    }

    // INNER

    global class Input {
        @InvocableVariable(label='SOQL Query' description='Query to be executed as Dynamic SOQL' required=true)
        global String dynamicSoqlQuery;
    }

    global class Output {
        @InvocableVariable(label='Result or Exception JSON' description='JSON array of result records or aggregate results on success, or exception object on error')
        global String resultOrException;
    }
}