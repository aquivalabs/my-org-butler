@IsTest
private class OpenAiApi_Test {
    
    @IsTest
    private static void getRequest() {

        // Setup
        Thread t = new Thread().id('123');

        new HttpMock()
                .get('aquiva_os__OpenAiApi/v1/threads/123').body(t).statusCodeOk()
                .mock();

        // Exercise
        Thread received = (Thread) new OpenAiApi('/threads/123').get(Thread.class);

        // Verify
        System.assertEquals(t.id, received.id);
    }

    
    @IsTest
    private static void postRequest() {

        // Setup
        Thread t = new Thread().id('123');

        new HttpMock()
                .post('aquiva_os__OpenAiApi/v1/threads').body(t).statusCodeOk()
                .mock();

        // Exercise
        Thread received = (Thread) new OpenAiApi('/threads').body(t).post(Thread.class);

        // Verify
        System.assertEquals(t.id, received.id);
    }

    @IsTest
    private static void errorCode() {

        // Setup
        Exception expectedException = null;

        new HttpMock()
                .get('aquiva_os__OpenAiApi/v1/threads').body(false).statusCode(500)
                .mock();

        // Exercise
        try {
            new OpenAiApi('/threads').get(Thread.class);
        }
        catch(ApplicationException ex) {
            expectedException = ex;
        }

        // Verify
        System.assertNotEquals(null, expectedException);
    }

    @IsTest
    private static void exception() {

        // Setup
        Exception expectedException = null;

        new HttpMock()
                .get('aquiva_os__OpenAiApi/v1/threads').statusCodeInternalServerError()
                .mock();

        // Exercise
        try {
            new OpenAiApi('/threads').get(Thread.class);
        }
        catch(ApplicationException ex) {
            expectedException = ex;
        }

        // Verify
        System.assertNotEquals(null, expectedException);
    }
}