/**
 * @author         Justus van den Berg (jfwberg@gmail.com)
 * @date           November 2024
 * @copyright      (c) 2024 Justus van den Berg
 * @license        MIT (See LICENSE file in the project root)
 * @description    Test class for the Wsdl class
 */
@Istest
private with sharing class WsdlTest {
    
    @IsTest
    private static void testHandleErrorsNoErrors() {
        
        // Create a new response for testing
        HttpResponse res = new HttpResponse();
        
        // Set the status 
        res.setStatusCode(200);
        res.setBody('<all>Good</all>');

        // Start the test
        Test.startTest();
         
        // Create the wsdl
        Wsdl wsdl = new MdtWsdl('readMetadata')
            .setItemMetadataType('CustomObjects')
            .addItemMetadataFullName('User')
            .setMockResponse(res)
            .call()
        ;

        // Validate that the returned wsdl is the same as the input Wsdl
        Wsdl errorHandlerResponseWsdl = Wsdl.handleErrors();

        Test.stopTest();

        // Handle assertions
        Assert.areEqual(
            wsdl,
            errorHandlerResponseWsdl,
            'Unexpected exception message'
        );
    }
    

    @IsTest
    private static void testHandleErrorsCodeCoverage() {
        
        // Create a new response for testing
        HttpResponse res = new HttpResponse();
        
        // Set the status to 999 specifically to hit code coverage and validate evrything is ignored
        res.setStatusCode(999);
        res.setBody('<all>Good</all>');

        // Start the test
        Test.startTest();
         
        // Create the wsdl
        Wsdl wsdl = new MdtWsdl('readMetadata')
            .setItemMetadataType('CustomObjects')
            .addItemMetadataFullName('User')
            .setMockResponse(res)
            .call()
        ;

        // Validate that the returned wsdl is the same as the input Wsdl
        Wsdl errorHandlerResponseWsdl = Wsdl.handleErrors();

        Test.stopTest();

        // Handle assertions
        Assert.areEqual(
            wsdl,
            errorHandlerResponseWsdl,
            'Unexpected exception message'
        );
    }  


    @IsTest
    private static void testHandleErrorsEmptyResponseBody() {
        
        // Assertion variables
        Wsdl.SoapApiException exceptionToAssert;

        // Create a new response for testing
        HttpResponse res = new HttpResponse();
        
        // Set the status to 999 specifically to hit code coverage and validate evrything is ignored
        res.setStatusCode(19);
        
        // Start the test
        Test.startTest();         
        try{
            // Create the wsdl
            Wsdl wsdl = new MdtWsdl('readMetadata')
                .setItemMetadataType('CustomObjects')
                .addItemMetadataFullName('User')
                .setMockResponse(res)
                .call()
                .handleErrors()
            ;

            // Safeguard
            throw new StringException('This part of the test should not be reached: An exception should have been thrown');

        }catch(Wsdl.SoapApiException e){
            exceptionToAssert = e;
        }
        Test.stopTest();

        // Handle assertions
        Assert.areEqual(
            Wsdl.MSG_HTTP_CALLOUT_ISSUE,
            exceptionToAssert.getMessage(),
            'Unexpected exception message'
        );
    }  


    @IsTest
    private static void testHandleErrorsInvalidResponseCode() {
        
        // Assertion variables
        Wsdl.SoapApiException exceptionToAssert;

        // Create a new response for testing
        HttpResponse res = new HttpResponse();
        
        // Set the status 
        res.setStatusCode(401);
        res.setBody('Unexpected response code body content');

        // Start the test
        Test.startTest();
        try{
            
            // Create the wsdl
            Wsdl wsdl = new MdtWsdl('readMetadata')
                .setItemMetadataType('CustomObjects')
                .addItemMetadataFullName('User')
                .setMockResponse(res)
                .call()
                .handleErrors()
            ;
            
            // Safeguard
            throw new StringException('This part of the test should not be reached: An exception should have been thrown');

        }catch(Wsdl.SoapApiException e){
            exceptionToAssert = e;
        }
        Test.stopTest();

        // Handle assertions
        Assert.areEqual(
            String.format(Wsdl.MSG_UNKNOWN_HTTP_STATUS_CODE,new String[]{'401','Unexpected response code body content'}),
            exceptionToAssert.getMessage(),
            'Unexpected exception message'
        );
    }   


    @IsTest
    private static void testHandleErrorsInvalidXml() {
        
        // Assertion variables
        Wsdl.SoapApiException exceptionToAssert;

        // Create a new response for testing
        HttpResponse res = new HttpResponse();
        
        // Set the status 
        res.setStatusCode(500);
        res.setBody('Invalid XML Body');

        // Start the test
        Test.startTest();
        try{
            
            // Create the wsdl
            Wsdl wsdl = new MdtWsdl('readMetadata')
                .setItemMetadataType('CustomObjects')
                .addItemMetadataFullName('User')
                .setMockResponse(res)
                .call()
                .handleErrors()
            ;
            
            // Safeguard
            throw new StringException('This part of the test should not be reached: An exception should have been thrown');

        }catch(Wsdl.SoapApiException e){
            exceptionToAssert = e;
        }
        Test.stopTest();

        // Handle assertions
        Assert.isTrue(
            exceptionToAssert.getMessage().startsWith(Wsdl.MSG_INVALID_XML_RESPONSE.substringBefore('{0}')),
            'Unexpected exception message'
        );
    }   


    @IsTest
    private static void testHandleErrorsUnknownErrorResponse(){
        
        // Assertion variables
        Wsdl.SoapApiException exceptionToAssert;

        // Create a new response for testing
        HttpResponse res = new HttpResponse();
        
        // Set the status 
        res.setStatusCode(500);
        res.setBody('<error>Unknown Error</error>');

        // Start the test
        Test.startTest();
        try{
            
            // Create the wsdl
            Wsdl wsdl = new MdtWsdl('readMetadata')
                .setItemMetadataType('CustomObjects')
                .addItemMetadataFullName('User')
                .setMockResponse(res)
                .call()
                .handleErrors()
            ;
            
            // Safeguard
            throw new StringException('This part of the test should not be reached: An exception should have been thrown');

        }catch(Wsdl.SoapApiException e){
            exceptionToAssert = e;
        }
        Test.stopTest();

        // Handle assertions
        Assert.areEqual(
            String.format(Wsdl.MSG_UNKNOWN_ERROR_RESPONSE,new String[]{'<error>Unknown Error</error>'}),
            exceptionToAssert.getMessage(),
            'Unexpected exception message'
        );
    }   


    @IsTest
    private static void testHandleErrorsExpectedErrorResponse(){
        
        // Assertion variables
        Wsdl.SoapApiException exceptionToAssert;

        // Create a new response for testing
        HttpResponse res = new HttpResponse();
        
        // Set the status 
        res.setStatusCode(500);
        res.setBody('<?xml version="1.0" encoding="UTF-8"?><soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:sf="urn:fault.partner.soap.sforce.com" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"><soapenv:Body><soapenv:Fault><faultcode>sf:INVALID_LOGIN</faultcode><faultstring>INVALID_LOGIN: Invalid username, password, security token; or user locked out.</faultstring><detail><sf:LoginFault xsi:type="sf:LoginFault"><sf:exceptionCode>INVALID_LOGIN</sf:exceptionCode><sf:exceptionMessage>Invalid username, password, security token; or user locked out.</sf:exceptionMessage></sf:LoginFault></detail></soapenv:Fault></soapenv:Body></soapenv:Envelope>');

        // Start the test
        Test.startTest();
        try{
            
            // Create the wsdl
            Wsdl wsdl = new MdtWsdl('readMetadata')
                .setItemMetadataType('CustomObjects')
                .addItemMetadataFullName('User')
                .setMockResponse(res)
                .call()
                .handleErrors()
            ;
            
            // Safeguard
            throw new StringException('This part of the test should not be reached: An exception should have been thrown');

        }catch(Wsdl.SoapApiException e){
            exceptionToAssert = e;
        }
        Test.stopTest();

        // Handle assertions
        Assert.areEqual(
            String.format('{0} :: {1}',new String[]{'INVALID_LOGIN','INVALID_LOGIN: Invalid username, password, security token; or user locked out.'}),
            exceptionToAssert.getMessage(),
            'Unexpected exception message'
        );
    }


    @IsTest
    private static void testGetXsr(){
        
        // Variables to assert
        String faultToAssert;

        // The response body
        String responseBody = '<?xml version="1.0" encoding="UTF-8"?><soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:sf="urn:fault.partner.soap.sforce.com" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"><soapenv:Body><soapenv:Fault><faultcode>sf:INVALID_LOGIN</faultcode><faultstring>INVALID_LOGIN: Invalid username, password, security token; or user locked out.</faultstring><detail><sf:LoginFault xsi:type="sf:LoginFault"><sf:exceptionCode>INVALID_LOGIN</sf:exceptionCode><sf:exceptionMessage>Invalid username, password, security token; or user locked out.</sf:exceptionMessage></sf:LoginFault></detail></soapenv:Fault></soapenv:Body></soapenv:Envelope>';

        // Create a new response for testing
        HttpResponse res = new HttpResponse();
        
        // Set the status 
        res.setStatusCode(500);
        res.setBody(responseBody);

        // Start the test
        Test.startTest();

        // Read metadata example: get the data for the User Object
        Wsdl wsdl = new MdtWsdl('readMetadata')
            .setItemMetadataType('CustomObject')
            .addItemMetadataFullName('User')
            .setMockResponse(res)
        ;

        // Execute through reader
        XmlStreamReader xsr = wsdl.getXsr(); 

        // Stream throught the XML Elements and handle accordingly
        while(xsr.hasNext()){
            if(xsr.getEventType()==XmlTag.START_ELEMENT){
                if(xsr.getLocalName() == 'faultstring'){
                    xsr.next();
                    faultToAssert = xsr.getText();
                    break;
                }
            }
            xsr.next();
        }
        Test.stopTest();

        // Handle assertions
        Assert.areEqual(
            'INVALID_LOGIN: Invalid username, password, security token; or user locked out.',
            faultToAssert,
            'Unexpected XML Element value'
        );

        // Check the execution time is set for the getXsr()
        Assert.isTrue(
            wsdl.getExecutionTime() > -1,
            'Unexpected execution time'
        );

        // There should be no response body stored for this method
        Assert.areEqual(
            null,
            wsdl.getResponse(),
            'Unexpected resposne Body'
        );
    }
}