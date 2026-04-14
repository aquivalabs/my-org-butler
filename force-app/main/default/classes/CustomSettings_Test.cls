@IsTest
private class CustomSettings_Test {

    @IsTest
    private static void returnsValueForExistingSetting() {

        // Setup
        CustomSettings.mock('TestSetting', 'test-value');

        // Exercise & Verify
        Assert.areEqual('test-value', CustomSettings.valueFor('TestSetting'));
    }


    @IsTest
    private static void throwsWhenSettingNotFound() {
        // Setup
        Exception expectedException = null;

        // Exercise
        try {
            CustomSettings.valueFor('NonExistent');
        } catch (ApplicationException e) {
            expectedException = e;
        }

        // Verify
        Assert.isNotNull(expectedException);
        Assert.areEqual('Custom Setting not found: NonExistent', expectedException.getMessage());
    }


    @IsTest
    private static void returnsNullForMissingOptionalSetting() {

        // Exercise
        String result = CustomSettings.optionalValueFor('NonExistent');

        // Verify
        Assert.isNull(result);
    }


    @IsTest
    private static void returnsValueForExistingOptionalSetting() {

        // Setup
        CustomSettings.mock('TestSetting', 'test-value');

        // Exercise
        String result = CustomSettings.optionalValueFor('TestSetting');

        // Verify
        Assert.areEqual('test-value', result);
    }
}