// PMD False Positives: Package Subscribers need to schedule this class
@SuppressWarnings('PMD.AvoidGlobalMethod')
global with sharing class NightlyMemoryConsolidation implements Database.Batchable<Id>, Schedulable {
    
    private static final String CONSOLIDATED_NAME = 'CONSOLIDATED_MEMORY';

    // GLOBAL

    global void execute(SchedulableContext context) {
        Database.executeBatch(new NightlyMemoryConsolidation());
    }
    
    // PUBLIC
    
    public Iterable<Id> start(Database.BatchableContext context) {
        Set<Id> usersWithUnconsolidatedMemory = new Set<Id>();
        
        for(Memory__c memory : [SELECT CreatedById
                               FROM Memory__c 
                               WHERE Name != :CONSOLIDATED_NAME
                               WITH SYSTEM_MODE]) {
            usersWithUnconsolidatedMemory.add(memory.CreatedById);
        }
        
        return usersWithUnconsolidatedMemory;
    }
    
    public void execute(Database.BatchableContext context, List<Id> userIds) {
        for(Id userId : userIds) {
            new AgentMemory(userId).consolidate();
        }
    }
    
    public void finish(Database.BatchableContext context) {
        // Memory consolidation complete
    }
}
