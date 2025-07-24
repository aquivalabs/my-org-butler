@IsTest
private class StoreCustomInstruction_Test {

    @IsTest
    private static void execute() {
        // Exercise
        StoreCustomInstruction.UpdateInput input = new StoreCustomInstruction.UpdateInput();
        input.summary = 'User prefers tables over lists';
        input.instruction = 'When user asks about projects, query Salesforce data and format results as tables instead of bullet lists for better readability';
        
        List<LoadCustomInstructions.CustomInstructions> response = StoreCustomInstruction.execute(new List<StoreCustomInstruction.UpdateInput>{ input });

        // Verify
        System.assertNotEquals(null, response);
        System.assertEquals(1, response.size());
        
        LoadCustomInstructions.CustomInstructions output = response[0];
        System.assertNotEquals(null, output.customInstructions);
        System.assert(output.customInstructions.contains('User-specific instructions:'));
        System.assert(output.customInstructions.contains('When user asks about projects'));
    }
}
