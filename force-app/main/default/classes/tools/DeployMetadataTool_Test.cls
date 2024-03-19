// PMD False Positive: Calling regular Salesforce APIs can be done with Session Id
@IsTest
private class DeployMetadataTool_Test {
    
    @IsTest
    private static void happyPath() {

        // Setup
        Test.setMock(WebServiceMock.class, new MetadataServiceTest.WebServiceMockImpl());

        String response = new DeployMetadataTool().execute('{ "files": [{ "fileName": "MyClass.cls", "fileContent": "public class MyClass {}" }] }');

        // Verify
        System.assertEquals('{"deploymentStatus":"Success"}', response);
    }
}