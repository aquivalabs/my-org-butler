// Note: Agentforce requires Global; session auth needed to call Data Cloud query API
@SuppressWarnings('PMD.AvoidGlobalModifier, PMD.ApexSuggestUsingNamedCred')
global with sharing class QueryDataCloud {

    public static HttpResponse mockedResponse = null;

    private static final String QUERY_ENDPOINT = '/services/data/v66.0/ssot/query-sql';

    @InvocableMethod(label='MyOrgButler: Run Data Cloud SQL Query'
                     description='Run a SQL query against Data Cloud and return results or errors')
    global static List<Output> execute(List<Input> inputs) {
        Output output = new Output();

        try {
            HttpResponse response = callApi(inputs[0].sqlQuery);
            output.resultOrException = buildResult(response.getBody());
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

    private static String buildResult(String responseBody) {
        Map<String, Object> parsed = (Map<String, Object>) JSON.deserializeUntyped(responseBody);

        List<Object> columns = (List<Object>) parsed.get('metadata');
        List<Object> rows = (List<Object>) parsed.get('data');
        String status = (String) parsed.get('completionStatus');

        List<String> columnNames = new List<String>();
        for(Object col : columns) {
            Map<String, Object> colMap = (Map<String, Object>) col;
            columnNames.add((String) colMap.get('name'));
        }

        List<Map<String, Object>> records = new List<Map<String, Object>>();
        if(rows == null) {
            rows = new List<Object>();
        }
        for(Object row : rows) {
            List<Object> values = (List<Object>) row;
            Map<String, Object> record = new Map<String, Object>();

            for(Integer i = 0; i < columnNames.size(); i++) {
                record.put(columnNames[i], values[i]);
            }

            records.add(record);
        }

        String result;

        if(status != null && status != 'COMPLETE') {
            Map<String, Object> envelope = new Map<String, Object>{
                'status' => 'PARTIAL',
                'message' => 'Query returned partial results. Narrow the query with WHERE or LIMIT.',
                'data' => records
            };
            result = JSON.serialize(envelope, true);
        }
        else {
            result = JSON.serialize(records, true);
        }

        return result;
    }


    private static HttpResponse callApi(String sqlQuery) {
        HttpResponse result = mockedResponse;

        if(result == null) {
            HttpRequest request = new HttpRequest();
            request.setMethod('POST');
            request.setHeader('Authorization', 'Bearer ' + new SessionId().asString());
            request.setHeader('Content-Type', 'application/json');
            request.setEndpoint(Url.getOrgDomainURL().toExternalForm() + QUERY_ENDPOINT);
            request.setBody(JSON.serialize(new Map<String, String>{ 'sql' => sqlQuery }));

            result = new Http().send(request);
        }

        if(result.getStatusCode() >= 400) {
            throw new DataCloudException('Data Cloud query error (' + result.getStatusCode() + '): ' + result.getBody());
        }

        return result;
    }


    // INNER

    global class Input {
        @InvocableVariable(label='SQL Query' description='SQL query to execute against Data Cloud' required=true)
        global String sqlQuery;

        // Note: Empty constructor required for Invocable Methods deserialization
        @SuppressWarnings('PMD.EmptyStatementBlock')
        global Input() {}
    }

    global class Output {
        @InvocableVariable(label='Result or Exception JSON' description='JSON array of result rows on success, or exception object on error')
        global String resultOrException;
    }

    public class DataCloudException extends Exception {}
}
