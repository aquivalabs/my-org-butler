// Note: Small stateless helper - no constructor or state needed, static access is cleaner
@SuppressWarnings('PMD.PreferRealObjectsOverStaticHelpers')
public with sharing class CustomSettings {
    
    public static String valueFor(String settingName) {
        CustomSetting__c setting = CustomSetting__c.getValues(settingName);
        
        if (setting == null) {
            throw new ApplicationException('Custom Setting not found: ' + settingName);
        }
        
        return setting.Value__c;
    }
    
    @TestVisible
    private static void mock(String settingName, String value) {
        CustomSetting__c setting = new CustomSetting__c(
            Name = settingName,
            Value__c = value
        );
        upsert as user setting;
    }
}
