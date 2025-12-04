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
        Assert.isNotNull(response);
        Assert.areEqual(1, response.size());

        LoadCustomInstructions.CustomInstructions output = response[0];
        Assert.isNotNull(output.customInstructions);
        Assert.isTrue(output.customInstructions.contains(System.UserInfo.getUserId()));
        Assert.isTrue(output.customInstructions.contains(System.UserInfo.getFirstName()));
        Assert.isTrue(output.customInstructions.contains(System.UserInfo.getLastName()));
        Assert.isTrue(output.customInstructions.contains(System.UserInfo.getOrganizationId()));
        Assert.isTrue(output.customInstructions.contains(URL.getOrgDomainUrl().toExternalForm()));
        Assert.isTrue(output.customInstructions.contains('- Test shared preference'));
        Assert.isTrue(output.customInstructions.contains('- Test user preference'));
    }
}
