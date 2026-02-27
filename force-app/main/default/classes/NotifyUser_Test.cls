@IsTest
private class NotifyUser_Test {


    @IsTest
    private static void sendsNotificationToSpecificUser() {

        // Setup
        NotifyUser.Input input = new NotifyUser.Input();
        input.body = 'Something happened in your org.';
        input.targetId = 'some-target';
        input.recipientIds = UserInfo.getUserId();

        // Exercise
        List<NotifyUser.Output> result = NotifyUser.execute(
            new List<NotifyUser.Input>{ input }
        );

        // Verify
        Assert.areEqual(1, result.size());
        Assert.areEqual('sent', result[0].status);
    }


    @IsTest
    private static void sendsNotificationToCurrentUserWhenNoRecipient() {

        // Setup
        NotifyUser.Input input = new NotifyUser.Input();
        input.body = 'Something happened in your org.';
        input.targetId = 'some-target';

        // Exercise
        List<NotifyUser.Output> result = NotifyUser.execute(
            new List<NotifyUser.Input>{ input }
        );

        // Verify
        Assert.areEqual(1, result.size());
        Assert.areEqual('sent', result[0].status);
    }
}
