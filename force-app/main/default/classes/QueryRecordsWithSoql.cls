// PMD False Positives:
// - Agentforce requires Global
// - AccessLevel.USER_MODE enforces FLS at runtime; SFGE can't resolve the dynamic SOQL string statically
@SuppressWarnings('PMD.AvoidGlobalModifier, PMD.ApexFlsViolation')
global with sharing class QueryRecordsWithSoql {

    @InvocableMethod(label='MyOrgButler: Run SOQL Queries' description='Run a single SOQL Query and return a list of records or errors. SELECT COUNT() returns a totalSize instead of records.')
    global static List<Output> execute(List<Input> input) {
        Output output = new Output();
        String query = input[0].dynamicSoqlQuery;

        try {
            if(isCount(query)) {
                output.resultOrException = JSON.serialize(new Map<String, Object>{
                    'totalSize' => Database.countQuery(query, AccessLevel.USER_MODE)
                });
            }
            else {
                String records = JSON.serialize(Database.query(query, AccessLevel.USER_MODE));
                output.resultOrException = records.replaceAll('(\\"url\\":\\")/services/data/v[0-9.]+/sobjects/[^/]+/', '$1/');
            }
        }
        catch(Exception ex) {
            Map<String, Object> exceptionInfo = new Map<String, Object>{
                'message' => ex.getMessage(),
                'typeName' => ex.getTypeName(),
                'stackTrace' => ex.getStackTraceString()
            };
            output.resultOrException = JSON.serialize(exceptionInfo);
        }

        return new List<Output>{ output };
    }


    // PRIVATE

    private static Boolean isCount(String query) {
        // Note: anchored and requiring empty parentheses, so COUNT(Id) or a Count__c field is not mistaken for a row count.
        return Pattern.matches('(?is)^select\\s+count\\s*\\(\\s*\\)\\s.*', query.trim());
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