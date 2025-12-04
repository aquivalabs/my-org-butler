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
        for(Memory__c memory : (List<Memory__c>)Database.query(memorySoql(), System.AccessLevel.SYSTEM_MODE)) {
            if(memory.Name == CONSOLIDATED_NAME) {
                consolidated = memory;
            } 
            else {
                newMemory.add(memory);
            }
        }
    }

    private String memorySoql() {
        String filter = (userId == null) ? 'IsShared__c = true' : 'CreatedById = :userId';
        return 'SELECT Id, Name, Content__c, CreatedDate FROM Memory__c WHERE ' + filter + ' ORDER BY CreatedDate ASC';
    }

    private String performConsolidation() {
        String existing = consolidated != null ? consolidated.Content__c : '';
        existing = (existing != null) ? existing.left(10000) : '';  // Limit to 10k characters to avoid API limits
        
        String newMemories = buildMemoryText();
        newMemories = newMemories.left(10000);  // Limit to 10k characters to avoid API limits
        
        String result = callPrompt(existing, newMemories);
        return result;
    }
    
    private String buildMemoryText() {
        List<String> lines = new List<String>();

        for(Memory__c memory : newMemory) {
            lines.add(memory.Name + ' : ' + memory.Content__c);
        }

        return String.join(lines, '\n');
    }
    
    private String callPrompt(String consolidated, String newMemories) {
        String result = 'Mock response';

        if(!Test.isRunningTest()) {
            ConnectApi.WrappedValue consolidatedMemoryValue = new ConnectApi.WrappedValue();
            consolidatedMemoryValue.value = consolidated;
            
            ConnectApi.WrappedValue newMemoryValue = new ConnectApi.WrappedValue();
            newMemoryValue.value = newMemories;
            
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
            
            result = output.generations[0].text;
        }

        return result;
    }
    
    private void updateConsolidated(String content) {
        consolidated.Name = CONSOLIDATED_NAME;
        consolidated.Content__c = content.left(32768);
        upsert consolidated;
    }
}