public with sharing class AgentMemory {
    
    private static final String CONSOLIDATED_NAME = 'CONSOLIDATED_MEMORY';
    
    private Id userId;
    private Memory__c consolidated = new Memory__c();
    private List<Memory__c> newMemory = new List<Memory__c>();

    // CTOR
    
    public AgentMemory() {
        this(UserInfo.getUserId());
    }
    
    public AgentMemory(Id userId) {
        this.userId = userId;
    }
   
    // PUBLIC
    
    public void consolidate() {
        queryMemories();

        if(newMemory.size() > 0) {
            String content = performConsolidation();
            updateConsolidated(content);
            delete newMemory;
        }
    }
    
    // PRIVATE
    
    private void queryMemories() {
        for(Memory__c memory : [SELECT Id, Name, Content__c, CreatedDate
                                FROM Memory__c 
                                WHERE CreatedById = :userId
                                WITH SYSTEM_MODE
                                ORDER BY CreatedDate ASC]) {
            if(memory.Name == CONSOLIDATED_NAME) {
                consolidated = memory;
            } else {
                newMemory.add(memory);
            }
        }
    }
    
    private String performConsolidation() {
        String existing = consolidated != null ? consolidated.Content__c : '';
        existing = (existing != null) ? existing.left(10000) : '';  // Limit to 10k characters to avoid API limits
        
        String newMemories = buildMemoryText();
        newMemories = newMemories.left(10000);  // Limit to 10k characters to avoid API limits
        
        // Try with the current class's approach first
        String result = callPrompt(existing, newMemories);
        
        // If we still got an error message, try the alternative approach
        if (result.startsWith('Failed to consolidate memory')) {
            result = callPromptAlternative(existing, newMemories);
        }
        
        return result;
    }
    
    private String callPromptAlternative(String consolidated, String newMemories) {
        try {
            // Try using the pattern from the working class (RetrieveVectorizeChunks)
            ConnectApi.EinsteinPromptTemplateGenerationsInput input = new ConnectApi.EinsteinPromptTemplateGenerationsInput();
            input.additionalConfig = new ConnectApi.EinsteinLlmAdditionalConfigInput();
            input.additionalConfig.applicationName = 'MyOrgButler';  // Try a different application name
            input.isPreview = false;
            
            // Create parameters
            ConnectApi.WrappedValue consolidatedParam = new ConnectApi.WrappedValue();
            consolidatedParam.value = consolidated;
            
            ConnectApi.WrappedValue newMemoriesParam = new ConnectApi.WrappedValue();
            newMemoriesParam.value = newMemories;
            
            // Set parameters
            input.inputParams = new Map<String, ConnectApi.WrappedValue>{
                'Input:consolidatedMemory' => consolidatedParam,
                'Input:newMemory' => newMemoriesParam
            };
            
            // Log attempt
            System.debug('Trying alternative approach with application name: MyOrgButler');
            
            // Try with a timeout
            Datetime startTime = Datetime.now();
            ConnectApi.EinsteinPromptTemplateGenerationsRepresentation output = 
                ConnectApi.EinsteinLLM.generateMessagesForPromptTemplate('ConsolidateMemory', input);
            
            return output.generations[0].text;
        } catch(Exception e) {
            System.debug(LoggingLevel.ERROR, 'Error in alternative approach: ' + e.getMessage());
            
            // Return a simple summary as fallback if everything fails
            return 'CONSOLIDATED MEMORY\n\n' + consolidated + '\n\nNEW MEMORIES\n\n' + newMemories;
        }
    }
    
    private String buildMemoryText() {
        List<String> lines = new List<String>();

        for(Memory__c memory : newMemory) {
            lines.add(memory.Name + ' : ' + memory.Content__c);
        }

        return String.join(lines, '\n');
    }
    
    private String callPrompt(String consolidated, String newMemories) {
        try {
            // Initialize wrapped values for the parameters
            ConnectApi.WrappedValue consolidatedMemoryValue = new ConnectApi.WrappedValue();
            consolidatedMemoryValue.value = consolidated;
            
            ConnectApi.WrappedValue newMemoryValue = new ConnectApi.WrappedValue();
            newMemoryValue.value = newMemories;
            
            // Setup input for the API call
            ConnectApi.EinsteinPromptTemplateGenerationsInput input = new ConnectApi.EinsteinPromptTemplateGenerationsInput();
            input.additionalConfig = new ConnectApi.EinsteinLlmAdditionalConfigInput();
            input.additionalConfig.applicationName = 'PromptBuilderPreview';
            input.isPreview = false;
            input.inputParams = new Map<String, ConnectApi.WrappedValue>{
                'Input:consolidatedMemory' => consolidatedMemoryValue,
                'Input:newMemory' => newMemoryValue
            };
            
            ConnectApi.EinsteinPromptTemplateGenerationsRepresentation output = 
                ConnectApi.EinsteinLLM.generateMessagesForPromptTemplate('ConsolidateMemory', input);
            
            return output.generations[0].text;
        } 
        catch(Exception e) {
            System.debug(LoggingLevel.ERROR, 'Error in AgentMemory.callPrompt: ' + e.getMessage() + '\n' + e.getStackTraceString());
            return 'Failed to consolidate memory due to error: ' + e.getMessage();
        }
    }
    
    private void updateConsolidated(String content) {
        consolidated.Name = CONSOLIDATED_NAME;
        consolidated.Content__c = content.left(32768);
        upsert consolidated;
    }
}