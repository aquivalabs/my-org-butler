@IsTest
private class DeployMetadataTool_Test {
    
    @IsTest
    private static void executeDeployment() {

        // Setup
        new HttpMock()
            .post('/services/data/v60.0/metadata/deployRequest', '{ "deploymentStatus" : "Success"}')
            .mock();

        String jsonParameter = '{ "files": [{ "name": "MyClass.cls", "content": "public class MyClass {}" }] }';
        
        // Exercise
        String response = new DeployMetadataTool().execute(jsonParameter);

        // Verify
        System.assertEquals('{"deploymentStatus":"Success"}', response);
    }
    
    @IsTest
    private static void exposesExceptions() {

        // Setup
        Exception expectedException = null;

        new HttpMock()
            .post('/services/data/v60.0/metadata/deployRequest', new ApplicationException())
            .mock();


        // Exercise
        try {
            new DeployMetadataTool().execute('{}');
        } catch (Exception ex) {
            expectedException = ex;
        }

        // Verify
        System.assertNotEquals(null, expectedException);
    }
}
