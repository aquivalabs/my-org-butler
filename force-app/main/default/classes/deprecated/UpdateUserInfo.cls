@SuppressWarnings('PMD.AvoidGlobalMethod')
global with sharing class UpdateUserInfo {

    @InvocableMethod(label='deprecated' description='deprecated')
    global static List<LoadUserInfo.UserInfo> execute(List<UpdateInput> inputs) {
        return new List<LoadUserInfo.UserInfo>();
    }

    // INNER

    global class UpdateInput {
        @InvocableVariable(label='deprecated' description='deprecated')
        global String summary;

        @InvocableVariable(label='deprecated' description='deprecated')
        global String instruction;
    }
}
