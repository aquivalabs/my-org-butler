@IsTest
private class CallSalesforceApiTool_Test {
    
    @IsTest
    private static void execute() {
        // Setup
        new HttpMock()
                .get('/services/rest').body('{ value : 3}').statusCodeOk()
                .mock();

        // Exercise
        String response = new CallSalesforceApiTool().execute(new Parameter().asJson());

        // Verify
        System.assertEquals('{ value : 3}', response);
    }
    
    @IsTest
    private static void exposesExceptions() {
        // Setup
        Exception expectedException = null;
        new HttpMock()
                .get('/services/rest').statusCodeInternalServerError()
                .mock();

        // Exercise
        try {
            new CallSalesforceApiTool().execute(new Parameter().asJson());
        }
        catch(ApplicationException ex) {
            expectedException = ex;
        }

        // Verify
        System.assertNotEquals(null, expectedException);
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