@IsTest
private class AgentMemory_Test {

    @IsTest
    private static void consolidateWithNoMemories() {
        // Exercise
        new AgentMemory().consolidate();

        // Verify
        List<Memory__c> memories = [SELECT Id FROM Memory__c];
        System.assertEquals(0, memories.size());
    }

    @IsTest
    private static void consolidateWithNewMemories() {
        // Setup
        insert new List<Memory__c>{
            new Memory__c(Name = 'Preference 1', Content__c = 'User likes tables'),
            new Memory__c(Name = 'Preference 2', Content__c = 'User prefers JSON format')
        };

        // Exercise
        new AgentMemory().consolidate();

        // Verify
        List<Memory__c> memories = [SELECT Name, Content__c FROM Memory__c];
        System.assertEquals(1, memories.size());
        System.assertEquals('CONSOLIDATED_MEMORY', memories[0].Name);
        // Should contain some consolidated content (either AI-generated or fallback)
        System.assert(memories[0].Content__c != null);
        System.assert(memories[0].Content__c.length() > 0);
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
        System.assertEquals(1, memories.size());
        System.assertEquals('CONSOLIDATED_MEMORY', memories[0].Name);
        // Should contain some consolidated content (either AI-generated or fallback)
        System.assert(memories[0].Content__c != null);
        System.assert(memories[0].Content__c.length() > 0);
    }

}
