@IsTest
private class OpenOrgPageTool_Test {
    
    @IsTest
    private static void execute() {

        // Setup
        Exception unexpectedException = null;
        String pageReferenceJson = '{ "type" : "standard__objectPage" }';

        
        // Exercise
        Database.SaveResult result;

        try {
            Test.startTest();
            String rawResult = new OpenOrgPageTool().setThreadId('123').execute(pageReferenceJson);
            result = (Database.SaveResult) JSON.deserialize(rawResult, Database.SaveResult.class);
            Test.stopTest();
        }
        catch(Exception ex) {
            unexpectedException = ex;
        }


        // Verify
        System.assertEquals(null, unexpectedException);
    }
}