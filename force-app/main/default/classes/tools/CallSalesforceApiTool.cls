public with sharing class CallSalesforceApiTool extends MyOrgButler.Tool {

    public override String execute(String paramsJson) {
        JsonParse parser = new JsonParse(paramsJson);

        CallSalesforceApi.Input input = new CallSalesforceApi.Input();
        input.httpMethod = parser.get('httpMethod').getStringValue();
        input.urlIncludingParams = parser.get('urlIncludingParams').getStringValue();
        
        // Make body parameter optional
        if(parser.exists('body', true)) {
            input.requestBody = parser.get('body').getStringValue();
        }

        List<CallSalesforceApi.Output> result = CallSalesforceApi.execute(new List<CallSalesforceApi.Input>{ input });
        return result[0].responseBody;
    }
}