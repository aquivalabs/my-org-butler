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
    private static void throwsOnMissingSetting() {
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
    private static void optionalSettingReturnsNull() {

        // Exercise
        String result = CustomSettings.optionalValueFor('NonExistent');

        // Verify
        Assert.isNull(result);
    }


    @IsTest
    private static void returnsOptionalValue() {

        // Setup
        CustomSettings.mock('TestSetting', 'test-value');

        // Exercise
        String result = CustomSettings.optionalValueFor('TestSetting');

        // Verify
        Assert.areEqual('test-value', result);
    }
}