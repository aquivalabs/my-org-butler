// PMD False Positives: 
public with sharing class GetUserContext{

    @InvocableMethod(label='MyOrgButler: Get User Context' description='Provides context information about the current user, including user details, time, date, and org information.'
    )
    public  static List<Context> execute(List<String> ignored) {
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

    public  class Context {
        @InvocableVariable(label='User ID' description='The ID of the current user.')
        public  String userId;
    
        @InvocableVariable(label='User First Name' description='The first name of the current user.')
        public  String userFirstName;
    
        @InvocableVariable(label='User Last Name' description='The last name of the current user.')
        public  String userLastName;
    
        @InvocableVariable(label='User Language' description='The language of the current user (e.g., en_US).')
        public  String userLanguage;
    
        @InvocableVariable(label='User Timezone' description='The timezone of the current user.')
        public  String userTimezone;
    
        @InvocableVariable(label='User Date and Time' description='The current date and time in the user’s timezone.')
        public  String userDateTime;
    
        @InvocableVariable(label='User Email' description='The email address of the current user.')
        public  String userEmail;
    
        @InvocableVariable(label='Base URL for Links' description='The base URL for constructing links in the current Salesforce org.')
        public  String baseUrlForLinks;
    
        @InvocableVariable(label='Organization ID' description='The ID of the Salesforce organization.')
        public  String orgId;
    }
    
}