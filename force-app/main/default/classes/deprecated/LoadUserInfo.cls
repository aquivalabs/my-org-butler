@SuppressWarnings('PMD.AvoidGlobalMethod')
@deprecated
global with sharing class LoadUserInfo {

    @InvocableMethod(label='MyOrgButler: Load User Info' description='Provides a formatted string with user context information including user details, time, date, and org information for AI agents.')
    global static List<UserInfo> execute(List<String> ignored) {
        return new List<UserInfo>();
    }


    // INNER
    @deprecated
    global class UserInfo {
        @InvocableVariable(label='deprecated' description='deprecated')
        global String userInfo;
    }
}
