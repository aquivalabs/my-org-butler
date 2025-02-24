public with sharing class RunSoqlQueryTool extends MyOrgButler.Tool {
    
    public override String execute(String paramsJson) {
        JsonParse parser = new JsonParse(paramsJson);

        RunSoqlQueries.Input request = new RunSoqlQueries.Input();
        request.dynamicSoqlQuery = parser.get('dynamicSoqlQuery').getStringValue();

        List<RunSoqlQueries.Output> result = RunSoqlQueries.execute(new List<RunSoqlQueries.Input>{ request });
        Map<String, Object> response = new Map<String, Object>{
            'result' => result[0].resultRecords,
            'error' => result[0].queryError
        };
        return JSON.serialize(response);
    }
}