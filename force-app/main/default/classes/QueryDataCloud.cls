// PMD False Positives: Agentforce requires Global
@SuppressWarnings('PMD.AvoidGlobalModifier')
global with sharing class QueryDataCloud {

    @TestVisible
    private static String mockedQueryResult;

    @InvocableMethod(label='MyOrgButler: Query Data Cloud' description='Run an ANSI SQL query against Data Cloud objects and return results or errors')
    global static List<Output> execute(List<Input> input) {
        Output output = new Output();

        try {
            output.resultOrException = executeQuery(input[0].sqlQuery);
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


    private static String executeQuery(String sql) {
        if(Test.isRunningTest() && mockedQueryResult != null) {
            return mockedQueryResult;
        }

        ConnectApi.CdpQueryInput input = new ConnectApi.CdpQueryInput();
        input.sql = sql;
        ConnectApi.CdpQueryOutputV2 result = ConnectApi.CdpQuery.queryAnsiSqlV2(input);

        // Build ordered field list from metadata (position → field name)
        Map<Integer, String> positionToField = new Map<Integer, String>();
        for(String fieldName : result.metadata.keySet()) {
            ConnectApi.CdpQueryMetadataItem meta = result.metadata.get(fieldName);
            positionToField.put(meta.placeInOrder, fieldName);
        }

        // Transform rows from positional arrays to named maps
        List<Map<String, Object>> records = new List<Map<String, Object>>();
        for(ConnectApi.CdpQueryV2Row row : result.data) {
            Map<String, Object> record = new Map<String, Object>();
            for(Integer i = 0; i < row.rowData.size(); i++) {
                String fieldName = positionToField.get(i);
                if(fieldName != null) {
                    record.put(fieldName, row.rowData[i]);
                }
            }
            records.add(record);
        }

        return JSON.serialize(records);
    }

    // INNER

    global class Input {
        @InvocableVariable(label='SQL Query' description='ANSI SQL query to execute against Data Cloud objects' required=true)
        global String sqlQuery;
    }

    global class Output {
        @InvocableVariable(label='Result or Exception JSON' description='JSON array of records (field name to value maps) on success, or exception object on error')
        global String resultOrException;
    }
}
