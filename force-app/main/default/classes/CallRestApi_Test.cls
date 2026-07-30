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
        Assert.areEqual('{ value : 3}', response[0].responseBody);
        Assert.isTrue(response[0].success);
    }


    @IsTest
    private static void executeOnForbidden() {
        // Setup
        new HttpMock()
                .patch('/services/rest').body('').statusCodeForbidden()
                .mock();

        CallRestApi.Input input = new CallRestApi.Input();
        input.httpMethod = 'PATCH';
        input.urlIncludingParams = '/services/rest';
        input.requestBody = '{ "Name" : "Acme" }';

        // Exercise
        List<CallRestApi.Output> response = CallRestApi.execute(new List<CallRestApi.Input>{ input });

        // Verify
        Assert.isFalse(response[0].success);
        Assert.isTrue(response[0].httpStatus.startsWith('403'));
    }
}
