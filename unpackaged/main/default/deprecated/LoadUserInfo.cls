@SuppressWarnings('PMD.AvoidGlobalMethod')
@deprecated
global with sharing class LoadUserInfo {

    @InvocableMethod(label='deprecated' description='deprecated')
    @deprecated
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
