/**
 * @author         Justus van den Berg (jfwberg@gmail.com)
 * @date           November 2024
 * @copyright      (c) 2024 Justus van den Berg
 * @license        MIT (See LICENSE file in the project root)
 * @description    Test class for the Partner Wsdl class
 */
@IsTest
@SuppressWarnings('PMD.ApexAssertionsShouldIncludeMessage')
private with sharing class ParWsdlTest {

    /**
      * PARTNER WSDL - LOGIN EXAMPLE
      */
    @IsTest
    static void testLogin(){
        // Create a new wsdl connected to the target org and execute the 'login' soap action
        Wsdl partnerWsdl = new ParWsdl(URL.getOrgDomainUrl().toExternalForm(), null, 'login')
            .setUsername('username@yourcompany.com')
            .setPassword('password-should-come-from-secure-vault')
            .setupRequest()
        ;

        Assert.areEqual(
            '<?xml version="1.0" encoding="UTF-8"?><soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:urn="urn:partner.soap.sforce.com"><soapenv:Header><urn:CallOptions><urn:client></urn:client><urn:defaultNamespace></urn:defaultNamespace></urn:CallOptions></soapenv:Header><soapenv:Body><urn:login><urn:username>username@yourcompany.com</urn:username><urn:password>password-should-come-from-secure-vault</urn:password></urn:login></soapenv:Body></soapenv:Envelope>',
            partnerWsdl.getRequest().getBody()
        );
    }


    /**
     * PARTNER WSDL - LOGOUT EXAMPLE
     */
    @IsTest
    static void testLogout(){
        // Create a new wsdl connected to the target org and execute the 'logout' soap action
        Wsdl partnerWsdl = new ParWsdl(URL.getOrgDomainUrl().toExternalForm(), Wsdl.VAL_BEARER_TOKEN_HIDDEN_MESSAGE, 'logout')
            .setupRequest()
        ;

        Assert.areEqual(
            '<?xml version="1.0" encoding="UTF-8"?><soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:urn="urn:partner.soap.sforce.com"><soapenv:Header><urn:SessionHeader><urn:sessionId>' + Wsdl.VAL_BEARER_TOKEN_HIDDEN_MESSAGE + '</urn:sessionId></urn:SessionHeader><urn:CallOptions><urn:client></urn:client><urn:defaultNamespace></urn:defaultNamespace></urn:CallOptions></soapenv:Header><soapenv:Body><urn:logout></urn:logout></soapenv:Body></soapenv:Envelope>',
            partnerWsdl.getRequest().getBody()
        );
    }


    /**
     * PARTNER WSDL - GET USER INFO
     */
    @IsTest
    static void testGetUserInfo(){
        // Create a new wsdl connected to the target org and execute the 'getUserInfo' soap action
        Wsdl partnerWsdl = new ParWsdl('namedCredentialName', 'getUserInfo')
            .setupRequest()
        ;

        Assert.areEqual(
            '<?xml version="1.0" encoding="UTF-8"?><soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:urn="urn:partner.soap.sforce.com"><soapenv:Header><urn:SessionHeader><urn:sessionId>{!$Credential.OAuthToken}</urn:sessionId></urn:SessionHeader><urn:CallOptions><urn:client></urn:client><urn:defaultNamespace></urn:defaultNamespace></urn:CallOptions></soapenv:Header><soapenv:Body><urn:getUserInfo></urn:getUserInfo></soapenv:Body></soapenv:Envelope>',
            partnerWsdl.getRequest().getBody()
        );
    }


    /**
      * PARTNER WSDL - SET PASSWORD
      */
    @IsTest
    static void testSetPassword(){
        // Create a new wsdl connected to the target org and execute the 'setPassword' soap action
        Wsdl partnerWsdl = new ParWsdl('setPassword')
            .setUserId(UserInfo.getUserId())
            .setPassword('password-should-come-from-secure-vault')
            .setupRequest()
        ;

        Assert.areEqual(
            '<?xml version="1.0" encoding="UTF-8"?><soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:urn="urn:partner.soap.sforce.com"><soapenv:Header><urn:SessionHeader><urn:sessionId>' + Wsdl.VAL_BEARER_TOKEN_HIDDEN_MESSAGE + '</urn:sessionId></urn:SessionHeader><urn:CallOptions><urn:client></urn:client><urn:defaultNamespace></urn:defaultNamespace></urn:CallOptions></soapenv:Header><soapenv:Body><urn:setPassword><urn:userId>'+UserInfo.getUserId()+'</urn:userId><urn:password>password-should-come-from-secure-vault</urn:password></urn:setPassword></soapenv:Body></soapenv:Envelope>',
            partnerWsdl.getRequest().getBody()
        );
    }


    /**
      * PARTNER WSDL - RESET PASSWORD
      */
    @IsTest
    static void testResetPassword(){
        // Create a new wsdl connected to the target org and execute the 'resetPassword' soap action
        Wsdl partnerWsdl = new ParWsdl(URL.getOrgDomainUrl().toExternalForm(), Wsdl.VAL_BEARER_TOKEN_HIDDEN_MESSAGE, 'resetPassword')
            .setUserId(UserInfo.getUserId())
            .setupRequest()
        ;
        
        Assert.areEqual(
            '<?xml version="1.0" encoding="UTF-8"?><soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:urn="urn:partner.soap.sforce.com"><soapenv:Header><urn:SessionHeader><urn:sessionId>' + Wsdl.VAL_BEARER_TOKEN_HIDDEN_MESSAGE + '</urn:sessionId></urn:SessionHeader><urn:CallOptions><urn:client></urn:client><urn:defaultNamespace></urn:defaultNamespace></urn:CallOptions></soapenv:Header><soapenv:Body><urn:resetPassword><urn:userId>'+UserInfo.getUserId()+'</urn:userId></urn:resetPassword></soapenv:Body></soapenv:Envelope>',
            partnerWsdl.getRequest().getBody()
        );
    }


    /**
      * PARTNER WSDL - DESCRIBE GLOBAL
      */
    @IsTest
    static void testDescribeGlobal(){
        // Create a new wsdl connected to the target org and execute the 'describeGlobal' soap action
        Wsdl partnerWsdl = new ParWsdl(URL.getOrgDomainUrl().toExternalForm(), Wsdl.VAL_BEARER_TOKEN_HIDDEN_MESSAGE, 'describeGlobal')
            .setupRequest()
        ;

        Assert.areEqual(
            '<?xml version="1.0" encoding="UTF-8"?><soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:urn="urn:partner.soap.sforce.com"><soapenv:Header><urn:SessionHeader><urn:sessionId>' + Wsdl.VAL_BEARER_TOKEN_HIDDEN_MESSAGE + '</urn:sessionId></urn:SessionHeader><urn:CallOptions><urn:client></urn:client><urn:defaultNamespace></urn:defaultNamespace></urn:CallOptions></soapenv:Header><soapenv:Body><urn:describeGlobal></urn:describeGlobal></soapenv:Body></soapenv:Envelope>',
            partnerWsdl.getRequest().getBody()
        );
    }


    /**
      * PARTNER WSDL - DESCRIBE SOBJECT
      */
    @IsTest
    static void testDescribeSObject(){
        // Create a new wsdl connected to the target org and execute the 'describeSObject' soap action
        Wsdl partnerWsdl = new ParWsdl(URL.getOrgDomainUrl().toExternalForm(), Wsdl.VAL_BEARER_TOKEN_HIDDEN_MESSAGE, 'describeSObject')
            .setSObjectType('User')
            .setupRequest()
        ;

        Assert.areEqual(
            '<?xml version="1.0" encoding="UTF-8"?><soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:urn="urn:partner.soap.sforce.com"><soapenv:Header><urn:SessionHeader><urn:sessionId>' + Wsdl.VAL_BEARER_TOKEN_HIDDEN_MESSAGE + '</urn:sessionId></urn:SessionHeader><urn:CallOptions><urn:client></urn:client><urn:defaultNamespace></urn:defaultNamespace></urn:CallOptions></soapenv:Header><soapenv:Body><urn:describeSObject><urn:sObjectType>User</urn:sObjectType></urn:describeSObject></soapenv:Body></soapenv:Envelope>',
            partnerWsdl.getRequest().getBody()
        );
    }


    /**
      * PARTNER WSDL - DESCRIBE SOBJECTS
      */
    @IsTest
    static void testDescribeSObjects(){
        // Create a new wsdl connected to the target org and execute the 'describeSObjects' soap action
        Wsdl partnerWsdl = new ParWsdl(URL.getOrgDomainUrl().toExternalForm(), Wsdl.VAL_BEARER_TOKEN_HIDDEN_MESSAGE, 'describeSObjects')
            .addSObjectType('User')
            .addSObjectType('Organization')
            .setupRequest()
        ;

        Assert.areEqual(
            '<?xml version="1.0" encoding="UTF-8"?><soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:urn="urn:partner.soap.sforce.com"><soapenv:Header><urn:SessionHeader><urn:sessionId>' + Wsdl.VAL_BEARER_TOKEN_HIDDEN_MESSAGE + '</urn:sessionId></urn:SessionHeader><urn:CallOptions><urn:client></urn:client><urn:defaultNamespace></urn:defaultNamespace></urn:CallOptions></soapenv:Header><soapenv:Body><urn:describeSObjects><urn:sObjectType>User</urn:sObjectType><urn:sObjectType>Organization</urn:sObjectType></urn:describeSObjects></soapenv:Body></soapenv:Envelope>',
            partnerWsdl.getRequest().getBody()
        );
    }
}
