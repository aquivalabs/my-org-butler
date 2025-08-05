@IsTest
private class UpdateUserInfo_Test {

    @IsTest
    private static void execute() {
        // Exercise
        UpdateUserInfo.UpdateInput input = new UpdateUserInfo.UpdateInput();
        input.summary = 'User prefers tables over lists';
        input.instruction = 'When user asks about projects, query Salesforce data and format results as tables instead of bullet lists for better readability';
        
        List<LoadUserInfo.UserInfo> response = UpdateUserInfo.execute(new List<UpdateUserInfo.UpdateInput>{ input });

        // Verify
        System.assertNotEquals(null, response);
        System.assertEquals(1, response.size());
        
        LoadUserInfo.UserInfo output = response[0];
        System.assertNotEquals(null, output.userInfo);
        System.assert(output.userInfo.contains('User-specific instructions:'));
        System.assert(output.userInfo.contains('When user asks about projects'));
    }
}
