// PMD False Positives: Agentforce requires Global
@SuppressWarnings('PMD.AvoidGlobalModifier')
global with sharing class StoreCustomInstruction {

    @InvocableMethod(label='MyOrgButler: Store Custom Instruction' description='Updates user context with learned preferences and instructions for future AI agent interactions.')
    global static List<LoadCustomInstructions.CustomInstructions> execute(List<Input> input) {
        Memory__c memory = new Memory__c();
        memory.Name = input[0].summary.left(80);
        memory.Content__c = input[0].instruction.left(255);
        if(input[0].isShared != null) {
            memory.IsShared__c = input[0].isShared;
        }
        
        insert as system memory;
        
        // Note: Return updated user info including the new memory
        return LoadCustomInstructions.execute(new List<String>());
    }

    // INNER

    global class Input {
        @InvocableVariable(label='Summary' description='Brief summary of the learned preference or behavior (max 80 characters)')
        global String summary;
        
        @InvocableVariable(label='Instruction' description='Contextual instruction for future behavior. Include the context (e.g. "When user asks about projects, query Salesforce data using...") and specific guidance (max 255 characters)')
        global String instruction;

        @InvocableVariable(label='Is Shared' description='Set to true to share this memory with other users in the org.' required='false')
        global Boolean isShared = false;
    }
}
