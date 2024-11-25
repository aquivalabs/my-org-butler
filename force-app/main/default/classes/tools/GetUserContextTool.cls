public with sharing class GetUserContextTool extends MyOrgButler.Tool {

    public override String execute(String ignored) {
        return JSON.serialize( getContext() );
    }

    @InvocableMethod
    public static List<Context> execute() {
        return new List<Context>{ getContext() };
    }

    // PRIVATE

    private static Context getContext() {
        Context result = new Context();
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

    // INNER

    public class Context {
        @InvocableVariable
        public String userId;
        @InvocableVariable
        public String userFirstName;
        @InvocableVariable
        public String userLastName;
        @InvocableVariable
        public String userLanguage;
        @InvocableVariable
        public String userTimezone;
        @InvocableVariable
        public String userDateTime;
        @InvocableVariable
        public String userEmail;
        @InvocableVariable
        public String baseUrlForLinks;
        @InvocableVariable
        public String orgId;
    }
}