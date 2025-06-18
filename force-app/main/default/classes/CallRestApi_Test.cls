@IsTest
private class CallRestApi_Test {
    
    @IsTest
    private static void execute() {
        // Setup
        new HttpMock()
                .get('/services/rest').body('{ value : 3}').statusCodeOk()
                .mock();

        CallRestApi.Input input = new CallRestApi.Input();
        input.httpMethod = 'GET';
        input.urlIncludingParams = '/services/rest';
        input.requestBody = null;

        // Exercise
        List<CallRestApi.Output> response = CallRestApi.execute(new List<CallRestApi.Input>{ input });

        // Verify
        System.assertEquals('{ value : 3}', response[0].responseBody);
    }
}
