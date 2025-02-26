public with sharing class CallToolingApiTool extends MyOrgButler.Tool {
    
    public override String execute(String paramsJson) {
        JsonParse parser = new JsonParse(paramsJson);

        CallToolingApi.ToolingDescription tooling = new CallToolingApi.ToolingDescription();
        tooling.action = parser.get('action').getStringValue();
        
        // Add optional parameters based on the action type
        if (parser.exists('objectType', true)) {
            tooling.objectType = parser.get('objectType').getStringValue();
        }
        if (parser.exists('soql', true)) {
            tooling.soql = parser.get('soql').getStringValue();
        }
        if (parser.exists('recordJson', true)) {
            tooling.recordJson = parser.get('recordJson').getStringValue();
        }
        if (parser.exists('recordId', true)) {
            tooling.recordId = parser.get('recordId').getStringValue();
        }
        
        List<CallToolingApi.Output> output = CallToolingApi.execute(new List<CallToolingApi.ToolingDescription>{ tooling });
        return output[0].responseBody;
    }
}