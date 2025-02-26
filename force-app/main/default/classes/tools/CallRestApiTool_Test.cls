@IsTest
private class CallRestApiTool_Test {
    
    @IsTest
    private static void execute() {
        // Setup
        new HttpMock()
                .get('/services/rest').body('{ value : 3}').statusCodeOk()
                .mock();

        // Exercise
        String response = new CallRestApiTool().execute(new Parameter().asJson());

        // Verify
        System.assertEquals('{ value : 3}', response);
    }

    // HELPER
    private class Parameter {
        String httpMethod = 'GET';
        String urlIncludingParams = '/services/rest';
        String body = null;

        String asJson() {
            return JSON.serialize(this);
        }
    }
}