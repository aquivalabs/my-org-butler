@IsTest
private class AgentMemory_Test {

    @IsTest
    private static void consolidateWithNoMemory() {
        
        // Exercise
        new AgentMemory().consolidate();

        // Verify
        List<Memory__c> memories = [SELECT Id FROM Memory__c];
        Assert.areEqual(0, memories.size());
    }

    @IsTest
    private static void consolidateWithNewMemory() {
        
        // Setup
        insert new List<Memory__c>{
            new Memory__c(Name = 'Preference 1', Content__c = 'User likes tables'),
            new Memory__c(Name = 'Preference 2', Content__c = 'User prefers JSON format')
        };

        // Exercise
        new AgentMemory().consolidate();

        // Verify
        List<Memory__c> memories = [SELECT Name, Content__c FROM Memory__c];
        Assert.areEqual(1, memories.size());
        Assert.areEqual('CONSOLIDATED_MEMORY', memories[0].Name);
        Assert.isNotNull(memories[0].Content__c);
        Assert.isTrue(memories[0].Content__c.length() > 0);
    }


    @IsTest
    private static void consolidateWithExistingConsolidated() {
        
        // Setup
        insert new List<Memory__c>{
            new Memory__c(Name = 'CONSOLIDATED_MEMORY', Content__c = 'Existing consolidated memory'),
            new Memory__c(Name = 'New Preference', Content__c = 'User wants detailed responses')
        };

        // Exercise
        new AgentMemory().consolidate();

        // Verify
        List<Memory__c> memories = [SELECT Name, Content__c FROM Memory__c];
        Assert.areEqual(1, memories.size());
        Assert.areEqual('CONSOLIDATED_MEMORY', memories[0].Name);
        Assert.isNotNull(memories[0].Content__c);
        Assert.isTrue(memories[0].Content__c.length() > 0);
    }


    @IsTest
    private static void consolidateSharedMemory() {
        
        // Setup
        insert new List<Memory__c>{
            new Memory__c(Name = 'Shared 1', Content__c = 'S1', IsShared__c = true),
            new Memory__c(Name = 'Shared 2', Content__c = 'S2', IsShared__c = true)
        };

        // Exercise
        new AgentMemory((Id)null).consolidate();

        // Verify
        List<Memory__c> memories = [SELECT Name, Content__c FROM Memory__c];
        Assert.areEqual(1, memories.size());
        Assert.areEqual('CONSOLIDATED_MEMORY', memories[0].Name);
        Assert.isNotNull(memories[0].Content__c);
        Assert.isTrue(memories[0].Content__c.length() > 0);
    }
}
