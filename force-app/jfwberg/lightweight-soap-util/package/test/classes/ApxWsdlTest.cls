/**
 * @author         Justus van den Berg (jfwberg@gmail.com)
 * @date           November 2024
 * @copyright      (c) 2024 Justus van den Berg
 * @license        MIT (See LICENSE file in the project root)
 * @description    Test class for the Apex Wsdl class
 */
@IsTest
@SuppressWarnings('PMD.ApexAssertionsShouldIncludeMessage')
private with sharing class ApxWsdlTest {

    /**
     * APEX WSDL - EXECUTE ANONYMOUS APEX EXAMPLE
     */
    @IsTest
    static void testExecuteAnonymous(){

        // Test with myDomain URL + Session Id
        Wsdl apexWsdl = new ApxWsdl(URL.getOrgDomainUrl().toExternalForm(), Wsdl.VAL_BEARER_TOKEN_HIDDEN_MESSAGE , 'executeAnonymous')
            .setCode('System.debug(12345);')
            .setLogLevel('DEBUG')
            .setLogCategory('APEX_CODE')
            .setupRequest()
        ;

        // Check the body is as expected
        Assert.areEqual(
            '<?xml version="1.0" encoding="UTF-8"?><soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:apex="http://soap.sforce.com/2006/08/apex"><soapenv:Header><apex:SessionHeader><apex:sessionId>' + Wsdl.VAL_BEARER_TOKEN_HIDDEN_MESSAGE  + '</apex:sessionId></apex:SessionHeader><apex:CallOptions><apex:client></apex:client><apex:defaultNamespace></apex:defaultNamespace></apex:CallOptions><apex:DebuggingHeader><apex:categories><apex:category>APEX_CODE</apex:category><apex:level>DEBUG</apex:level></apex:categories><apex:debugLevel>NONE</apex:debugLevel></apex:DebuggingHeader></soapenv:Header><soapenv:Body><apex:executeAnonymous><String>System.debug(12345);</String></apex:executeAnonymous></soapenv:Body></soapenv:Envelope>',
            apexWsdl.getRequest().getBody()
        );
    }


    /**
     * APEX WSDL - COMPILE CLASSES EXAMPLE
     */
    @IsTest
    static void testCompileClasses(){

        // Test with named credential
        Wsdl apexWsdl = new ApxWsdl('testNamedCredential','compileClasses')
            .addScript('public class demo{}')
            .setupRequest()
        ;

        // Check the body is as expected
        Assert.areEqual(
            '<?xml version="1.0" encoding="UTF-8"?><soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:apex="http://soap.sforce.com/2006/08/apex"><soapenv:Header><apex:SessionHeader><apex:sessionId>' + Wsdl.VAL_NC_TOKEN_MERGE_VARIABLE + '</apex:sessionId></apex:SessionHeader><apex:CallOptions><apex:client></apex:client><apex:defaultNamespace></apex:defaultNamespace></apex:CallOptions><apex:DebuggingHeader><apex:categories><apex:category>APEX_CODE</apex:category><apex:level>ERROR</apex:level></apex:categories><apex:debugLevel>NONE</apex:debugLevel></apex:DebuggingHeader></soapenv:Header><soapenv:Body><apex:compileClasses><scripts>public class demo{}</scripts></apex:compileClasses></soapenv:Body></soapenv:Envelope>',
            apexWsdl.getRequest().getBody()
        );
    }


    /**
     * APEX WSDL - COMPILE TRIGGERS EXAMPLE
     */
    @IsTest
    static void testCompileTriggers(){

        // Test with no session Id and no my domain Url, so connect to self
        Wsdl apexWsdl = new ApxWsdl('compileTriggers')
            .addScript('trigger UserTrigger on User( before insert){}')
            .setupRequest()
        ;

        // Check the body is as expected
        Assert.areEqual(
            '<?xml version="1.0" encoding="UTF-8"?><soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:apex="http://soap.sforce.com/2006/08/apex"><soapenv:Header><apex:SessionHeader><apex:sessionId>' + Wsdl.VAL_BEARER_TOKEN_HIDDEN_MESSAGE + '</apex:sessionId></apex:SessionHeader><apex:CallOptions><apex:client></apex:client><apex:defaultNamespace></apex:defaultNamespace></apex:CallOptions><apex:DebuggingHeader><apex:categories><apex:category>APEX_CODE</apex:category><apex:level>ERROR</apex:level></apex:categories><apex:debugLevel>NONE</apex:debugLevel></apex:DebuggingHeader></soapenv:Header><soapenv:Body><apex:compileTriggers><scripts>trigger UserTrigger on User( before insert){}</scripts></apex:compileTriggers></soapenv:Body></soapenv:Envelope>',
            apexWsdl.getRequest().getBody()
        );
    }
}
