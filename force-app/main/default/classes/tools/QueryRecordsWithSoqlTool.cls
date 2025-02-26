public with sharing class QueryRecordsWithSoqlTool extends MyOrgButler.Tool {
    
    public override String execute(String paramsJson) {
        JsonParse parser = new JsonParse(paramsJson);

        QueryRecordsWithSoql.Input request = new QueryRecordsWithSoql.Input();
        request.dynamicSoqlQuery = parser.get('dynamicSoqlQuery').getStringValue();

        List<QueryRecordsWithSoql.Output> result = QueryRecordsWithSoql.execute(new List<QueryRecordsWithSoql.Input>{ request });
        Map<String, Object> response = new Map<String, Object>{
            'result' => result[0].resultRecords,
            'error' => result[0].queryError
        };
        return JSON.serialize(response);
    }
}