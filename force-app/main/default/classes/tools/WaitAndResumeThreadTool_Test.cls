@IsTest
private class WaitAndResumeThreadTool_Test {
    
    @IsTest
    private static void execute() {

        // Setup
        String paramsJson = '{ "minutesToWait" : 3 }';

        
        // Exercise
        String rawResult = new  WaitAndResumeThreadTool().setThreadId('123').execute(paramsJson);
        
        
        // Verify
        Map<String, Object> result = (Map<String, Object>) JSON.deserializeUntyped(rawResult);
        System.assertNotEquals(null, result.get('scheduledJobId'));
    }
}