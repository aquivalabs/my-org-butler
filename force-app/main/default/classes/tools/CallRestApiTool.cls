public with sharing class CallRestApiTool extends MyOrgButler.Tool {

    public override String execute(String paramsJson) {
        JsonParse parser = new JsonParse(paramsJson);

        CallRestApi.Input input = new CallRestApi.Input();
        input.httpMethod = parser.get('httpMethod').getStringValue();
        input.urlIncludingParams = parser.get('urlIncludingParams').getStringValue();
        
        // Make body parameter optional
        if(parser.exists('body', true)) {
            input.requestBody = parser.get('body').getStringValue();
        }

        List<CallRestApi.Output> result = CallRestApi.execute(new List<CallRestApi.Input>{ input });
        return result[0].responseBody;
    }
}