@IsTest
private class NotifyUser_Test {


    @IsTest
    private static void sendsNotificationToCurrentUser() {

        // Setup
        NotifyUser.Input input = new NotifyUser.Input();
        input.body = 'Something happened in your org.';
        input.targetId = 'some-target';
        input.recipientIds = new List<String>{ UserInfo.getUserId() };

        // Exercise
        List<NotifyUser.Output> result = NotifyUser.execute(
            new List<NotifyUser.Input>{ input }
        );

        // Verify
        Assert.areEqual(1, result.size());
        Assert.areEqual('sent', result[0].status);
    }
}
