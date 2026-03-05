// PMD False Positives: Agentforce requires Global
@SuppressWarnings('PMD.AvoidGlobalModifier')
global with sharing class ExploreDataCloudSchema {

    @TestVisible
    private static String mockedResult;

    @InvocableMethod(label='MyOrgButler: Explore Data Cloud Schema' description='Discover available fields on a Data Cloud object')
    global static List<Output> execute(List<Input> input) {
        Output output = new Output();

        try {
            output.resultOrException = describeObject(input[0].objectName);
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

    @TestVisible
    private static String describeObject(String objectName) {
        if(Test.isRunningTest() && mockedResult != null) {
            return mockedResult;
        }

        ConnectApi.CdpQueryInput input = new ConnectApi.CdpQueryInput();
        input.sql = 'SELECT * FROM ' + String.escapeSingleQuotes(objectName) + ' LIMIT 1';
        ConnectApi.CdpQueryOutputV2 result = ConnectApi.CdpQuery.queryAnsiSqlV2(input);

        return JSON.serialize(result.metadata);
    }

    // INNER

    global class Input {
        @InvocableVariable(label='Object Name' description='API name of the Data Cloud object (e.g. ssot__Opportunity__dlm)' required=true)
        global String objectName;
    }

    global class Output {
        @InvocableVariable(label='Result or Exception JSON' description='JSON object mapping field names to their type and position, or exception on error')
        global String resultOrException;
    }
}
