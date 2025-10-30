@IsTest
private class LoadCustomInstructions_Test {

    @IsTest
    private static void execute() {

        // Setup
        insert new Memory__c(Content__c = 'Test shared preference', IsShared__c = true);
        insert new Memory__c(Content__c = 'Test user preference', IsShared__c = false);

        // Exercise
        List<LoadCustomInstructions.CustomInstructions> response = LoadCustomInstructions.execute(new List<String>());

        // Verify
        System.assertNotEquals(null, response);
        System.assertEquals(1, response.size());

        LoadCustomInstructions.CustomInstructions output = response[0];
        System.assertNotEquals(null, output.customInstructions);
        System.assert(output.customInstructions.contains(System.UserInfo.getUserId()));
        System.assert(output.customInstructions.contains(System.UserInfo.getFirstName()));
        System.assert(output.customInstructions.contains(System.UserInfo.getLastName()));
        System.assert(output.customInstructions.contains(System.UserInfo.getOrganizationId()));
        System.assert(output.customInstructions.contains(URL.getOrgDomainUrl().toExternalForm()));
        System.assert(output.customInstructions.contains('- Test shared preference'));
        System.assert(output.customInstructions.contains('- Test user preference'));
    }
}
