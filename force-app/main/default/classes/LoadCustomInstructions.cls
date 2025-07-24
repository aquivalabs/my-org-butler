// PMD False Positives: Agentforce requires Global
@SuppressWarnings('PMD.AvoidGlobalMethod')
global with sharing class LoadCustomInstructions {

    @InvocableMethod(label='MyOrgButler: Load Custom Instructions' description='Provides a formatted string with user context information including user details, time, date, and org information for AI agents.')
    global static List<CustomInstructions> execute(List<String> ignored) {
        return new List<CustomInstructions>{ getCustomInstructions() };
    }

    // PRIVATE

    private static CustomInstructions getCustomInstructions() {
        List<String> lines = new List<String>();
        lines.add('\n### Basic User Info');
        lines.add('- Salesforce ID: ' + System.UserInfo.getUserId());
        lines.add('- First name: ' + System.UserInfo.getFirstName());
        lines.add('- Last name: ' + System.UserInfo.getLastName());
        lines.add('- Language: ' + System.UserInfo.getLanguage());
        lines.add('- Timezone in this org: ' + System.UserInfo.getTimeZone().getID());
        lines.add('- Current date and time: ' + System.now().format('E, dd MMM yyyy HH:mm:ss z'));
        lines.add('- Email address: ' + System.UserInfo.getUserEmail());
        lines.add('- Base URL for constructing links in this org: ' + URL.getOrgDomainUrl().toExternalForm());
        lines.add('- Salesforce organization ID: ' + System.UserInfo.getOrganizationId());

        lines.add('\n### User-specific instructions:');
            
        for (Memory__c memory : [SELECT Content__c FROM Memory__c WHERE CreatedById = :System.UserInfo.getUserId() WITH SYSTEM_MODE ORDER BY CreatedDate DESC]) {
            lines.add('- ' + memory.Content__c.trim());
        }
        
        CustomInstructions result = new CustomInstructions();
        result.customInstructions = String.join(lines, '\n');
        return result;
    }

    // INNER

    global class CustomInstructions {
        @InvocableVariable(label='Custom Instructions' description='Formatted string containing all user context information for AI agents.')
        global String customInstructions;
    }
}
