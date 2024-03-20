@IsTest
private class DeployMetadataTool_Test {
    
    @IsTest
    private static void happyPath() {

        // Setup
        Exception unexpectedException = null;
        Test.setMock(WebServiceMock.class, new MetadataServiceTest.WebServiceMockImpl());

        // Exercise
        try {
            new DeployMetadataTool().execute('{ "files": [{ "fileName": "MyClass.cls", "fileContent": "public class MyClass {}" }] }');
        }
        catch(Exception ex) {
            unexpectedException = ex;
        }

        // Verify
        System.assertEquals(null, unexpectedException);
    }
}