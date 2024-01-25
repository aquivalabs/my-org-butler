@IsTest
private class SendInOrgNotification_Test {
    
    @IsTest
    private static void execute() {

        // Setup
        Exception unexpectedException = null;

        new HttpMock().post('/services/data/v58.0/actions/standard/customNotificationAction', true).mock();
        String paramsJson = '{ "title" : "test", "body" : "Hello World", "targetId" : "000000000000000AAA"}';

        // Exercise
        try {
            new SendInOrgNotification().execute(paramsJson);
        }
        catch(Exception e) {
            unexpectedException = e;
        }

        // Verify
        System.assertEquals(null, unexpectedException);
    }
}