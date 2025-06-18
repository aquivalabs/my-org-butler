@IsTest
private class GetUserContext_Test {

    @IsTest
    private static void execute() {
        // Exercise
        List<GetUserContext.Context> response = GetUserContext.execute(new List<String>{ '' });

        // Verify
        System.assertNotEquals(null, response);
        System.assertEquals(1, response.size());
        GetUserContext.Context output = response[0];
        System.assertEquals(UserInfo.getUserId(), output.userId);
        System.assertEquals(UserInfo.getFirstName(), output.userFirstName);
        System.assertEquals(UserInfo.getLastName(), output.userLastName);
        System.assertEquals(UserInfo.getLanguage(), output.userLanguage);
        System.assertEquals(UserInfo.getTimeZone().getID(), output.userTimezone);
        System.assertEquals(UserInfo.getUserEmail(), output.userEmail);
        System.assertEquals(URL.getOrgDomainUrl().toExternalForm(), output.baseUrlForLinks);
        System.assertEquals(UserInfo.getOrganizationId(), output.orgId);
    }
}
