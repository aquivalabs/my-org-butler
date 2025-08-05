// PMD False Positives: Agentforce requires Global
@SuppressWarnings('PMD.AvoidGlobalMethod')
global with sharing class UpdateUserInfo {

    @InvocableMethod(label='MyOrgButler: Update User Info' description='Updates user context with learned preferences and instructions for future AI agent interactions.')
    global static List<LoadUserInfo.UserInfo> execute(List<UpdateInput> inputs) {
        
        for (UpdateInput input : inputs) {
            Memory__c memory = new Memory__c();
            memory.Name = input.summary.left(80);
            memory.Content__c = input.instruction.left(255);
            
            insert as system memory;
        }
        
        // Return updated user info including the new memory
        return LoadUserInfo.execute(new List<String>());
    }

    // INNER

    global class UpdateInput {
        @InvocableVariable(label='Summary' description='Brief summary of the learned preference or behavior (max 80 characters)')
        global String summary;
        
        @InvocableVariable(label='Instruction' description='Contextual instruction for future behavior. Include the context (e.g. "When user asks about projects, query Salesforce data using...") and specific guidance (max 255 characters)')
        global String instruction;
    }
}
