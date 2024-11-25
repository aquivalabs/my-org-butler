@IsTest
private class GetUserContextTool_Test {

    @IsTest
    private static void execute() {
        // Exercise
        String response = new GetUserContextTool().execute('');

        // Verify
        System.assertNotEquals(null, response);
        GetUserContextTool.Context output = (GetUserContextTool.Context) JSON.deserialize(response, GetUserContextTool.Context.class);
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
