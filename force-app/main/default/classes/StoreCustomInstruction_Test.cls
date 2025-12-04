@IsTest
private class StoreCustomInstruction_Test {

    @IsTest
    private static void execute() {
        
        // Exercise
        StoreCustomInstruction.Input input = new StoreCustomInstruction.Input();
        input.summary = 'User prefers tables over lists';
        input.instruction = 'When user asks about projects, query Salesforce data and format results as tables instead of bullet lists for better readability';
        
        List<LoadCustomInstructions.CustomInstructions> response = StoreCustomInstruction.execute(new List<StoreCustomInstruction.Input>{ input });

        // Verify
        Assert.isNotNull(response);
        Assert.areEqual(1, response.size());
        
        LoadCustomInstructions.CustomInstructions output = response[0];
        Assert.isNotNull(output.customInstructions);
        Assert.isTrue(output.customInstructions.contains('When user asks about projects'));
    }


    @IsTest
    private static void executeShared() {

        // Exercise
        StoreCustomInstruction.Input input = new StoreCustomInstruction.Input();
        input.summary = 'User prefers tables over lists';
        input.instruction = 'When user asks about projects, query Salesforce data and format results as tables instead of bullet lists for better readability';
        input.isShared = true;
        
        StoreCustomInstruction.execute(new List<StoreCustomInstruction.Input>{ input });


        // Verify
        Memory__c memory = [SELECT IsShared__c FROM Memory__c LIMIT 1];
        Assert.areEqual(true, memory.IsShared__c);
    }
}
