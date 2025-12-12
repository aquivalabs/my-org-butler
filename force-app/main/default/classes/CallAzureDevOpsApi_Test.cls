@IsTest
private class CallAzureDevOpsApi_Test {
    
    @IsTest
    private static void execute() {
        // Setup
        new HttpMock()
                .get('/_apis/projects?api-version=7.0').body('{ "count": 1, "value": [{ "name": "MyProject" }] }').statusCodeOk()
                .mock();

        CallAzureDevOpsApi.Input input = new CallAzureDevOpsApi.Input();
        input.urlIncludingParams = '/_apis/projects?api-version=7.0';
        input.httpMethod = 'GET';
        input.requestBody = null;

        // Exercise
        List<CallAzureDevOpsApi.Output> response = CallAzureDevOpsApi.execute(new List<CallAzureDevOpsApi.Input>{ input });

        // Verify
        System.assertEquals('{ "count": 1, "value": [{ "name": "MyProject" }] }', response[0].responseBody);
    }

    @IsTest
    private static void executeWithBody() {
        // Setup
        String requestBody = '{ "name": "NewWorkItem", "type": "Task" }';
        new HttpMock()
                .post('/_apis/wit/workitems/$Task?api-version=7.0').body('{ "id": 123, "fields": { "System.Title": "NewWorkItem" } }').statusCodeOk()
                .mock();

        CallAzureDevOpsApi.Input input = new CallAzureDevOpsApi.Input();
        input.urlIncludingParams = '/_apis/wit/workitems/$Task?api-version=7.0';
        input.httpMethod = 'POST';
        input.requestBody = requestBody;

        // Exercise
        List<CallAzureDevOpsApi.Output> response = CallAzureDevOpsApi.execute(new List<CallAzureDevOpsApi.Input>{ input });

        // Verify
        System.assertEquals('{ "id": 123, "fields": { "System.Title": "NewWorkItem" } }', response[0].responseBody);
    }
}
