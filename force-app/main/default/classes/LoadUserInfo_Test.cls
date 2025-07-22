@IsTest
private class LoadUserInfo_Test {

    @IsTest
    private static void execute() {
        // Exercise
        List<LoadUserInfo.UserInfo> response = LoadUserInfo.execute(new List<String>());

        // Verify
        System.assertNotEquals(null, response);
        System.assertEquals(1, response.size());

        LoadUserInfo.UserInfo output = response[0];
        System.assertNotEquals(null, output.userInfo);
        System.assert(output.userInfo.contains(System.UserInfo.getUserId()));
        System.assert(output.userInfo.contains(System.UserInfo.getFirstName()));
        System.assert(output.userInfo.contains(System.UserInfo.getLastName()));
        System.assert(output.userInfo.contains(System.UserInfo.getOrganizationId()));
        System.assert(output.userInfo.contains(URL.getOrgDomainUrl().toExternalForm()));
    }

    @IsTest 
    private static void executeWithMemory() {

        // Setup
        insert new Memory__c(Content__c = 'Test user preference');
        
        // Exercise
        List<LoadUserInfo.UserInfo> response = LoadUserInfo.execute(new List<String>());

        // Verify
        LoadUserInfo.UserInfo output = response[0];
        System.assert(output.userInfo.contains('User-specific instructions:'));
        System.assert(output.userInfo.contains('- Test user preference'));
    }
}
