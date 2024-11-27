public with sharing class GetUserContextTool extends MyOrgButler.Tool {

    public override String execute(String ignored) {
        return JSON.serialize( getContext() );
    }

    // PRIVATE

    private static GetUserContext.Context getContext() {
        GetUserContext.Context result = new GetUserContext.Context();
        result.userId = UserInfo.getUserId();
        result.userFirstName = UserInfo.getFirstName();
        result.userLastName = UserInfo.getLastName();
        result.userLanguage = UserInfo.getLanguage();
        result.userTimezone = UserInfo.getTimeZone().getID();
        result.userDateTime = System.now().format('E, dd MMM yyyy HH:mm:ss z');
        result.userEmail = UserInfo.getUserEmail();
        result.baseUrlForLinks = URL.getOrgDomainUrl().toExternalForm();
        result.orgId = UserInfo.getOrganizationId();
        return result;
    }
}