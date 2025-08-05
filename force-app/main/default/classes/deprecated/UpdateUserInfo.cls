@SuppressWarnings('PMD.AvoidGlobalMethod')
@deprecated
global with sharing class UpdateUserInfo {

    @InvocableMethod(label='MyOrgButler: Update User Info' description='Updates user context with learned preferences and instructions for future AI agent interactions.')
    global static List<LoadUserInfo.UserInfo> execute(List<UpdateInput> inputs) {
        return new List<LoadUserInfo.UserInfo>();
    }

    // INNER

    @deprecated
    global class UpdateInput {
        @InvocableVariable(label='deprecated' description='deprecated')
        global String summary;

        @InvocableVariable(label='deprecated' description='deprecated')
        global String instruction;
    }
}
