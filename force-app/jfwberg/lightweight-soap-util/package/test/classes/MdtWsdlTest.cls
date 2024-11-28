/**
 * @author         Justus van den Berg (jfwberg@gmail.com)
 * @date           November 2024
 * @copyright      (c) 2024 Justus van den Berg
 * @license        MIT (See LICENSE file in the project root)
 * @description    Test class for the Metadata Wsdl class
 */
@IsTest
@SuppressWarnings('PMD.ApexAssertionsShouldIncludeMessage')
private with sharing class MdtWsdlTest {

    /**
      * METADATA WSDL - DESCRIBE METADATA EXAMPLE
      */
    @IsTest
    static void testDescribeMetadata(){

        // Create a new wsdl to the current org and set the soap action to 'describeMetadata'
        Wsdl metadataWsdl = new MdtWsdl('namedCredentialName','describeMetadata')
            .setupRequest()
            .setApiVersion('v60.0')
        ;
        
        // Check the body is as expected
        Assert.areEqual(
            '<?xml version="1.0" encoding="UTF-8"?><soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:mdt="http://soap.sforce.com/2006/04/metadata"><soapenv:Header><mdt:SessionHeader><mdt:sessionId>{!$Credential.OAuthToken}</mdt:sessionId></mdt:SessionHeader><mdt:CallOptions><mdt:client></mdt:client><mdt:defaultNamespace></mdt:defaultNamespace></mdt:CallOptions><mdt:AllOrNoneHeader><mdt:allOrNone>true</mdt:allOrNone></mdt:AllOrNoneHeader></soapenv:Header><soapenv:Body><mdt:describeMetadata></mdt:describeMetadata></soapenv:Body></soapenv:Envelope>',
            metadataWsdl.getRequest().getBody()
        );
    }


    /**
      * METADATA WSDL - LIST METADATA EXAMPLE
      */
    @IsTest
    static void testListMetadata(){

        // Create a new wsdl to the current org and set the soap action to 'listMetadata'
        Wsdl metadataWsdl = new MdtWsdl('listMetadata')
            .addListMetadata('LightningMessageChannel')
            .addListMetadata('ReportFolder')
            .addListMetadata('Report','unfiled$public')
            .setupRequest()
        ;

        // Check the body is as expected
        Assert.areEqual(
            '<?xml version="1.0" encoding="UTF-8"?><soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:mdt="http://soap.sforce.com/2006/04/metadata"><soapenv:Header><mdt:SessionHeader><mdt:sessionId>'+ Wsdl.VAL_BEARER_TOKEN_HIDDEN_MESSAGE +'</mdt:sessionId></mdt:SessionHeader><mdt:CallOptions><mdt:client></mdt:client><mdt:defaultNamespace></mdt:defaultNamespace></mdt:CallOptions><mdt:AllOrNoneHeader><mdt:allOrNone>true</mdt:allOrNone></mdt:AllOrNoneHeader></soapenv:Header><soapenv:Body><mdt:listMetadata><queries><folder></folder><type>LightningMessageChannel</type></queries><queries><folder></folder><type>ReportFolder</type></queries><queries><folder>unfiled$public</folder><type>Report</type></queries></mdt:listMetadata></soapenv:Body></soapenv:Envelope>',
            metadataWsdl.getRequest().getBody()
        );
    }


    /**
     * METADATA WSDL - READ METADATA EXAMPLE
     */
    @IsTest
    static void testReadMetadata(){
        // Create a new wsdl to the current org and set the soap action to 'readMetadata'
        Wsdl metadataWsdl = new MdtWsdl(URL.getOrgDomainUrl().toExternalForm(), Wsdl.VAL_BEARER_TOKEN_HIDDEN_MESSAGE, 'readMetadata')
            .setItemMetadataType('CustomObject')
            .addItemMetadataFullName('User')
            .addItemMetadataFullName('Account')
            .setupRequest()
        ;

        // Check the body is as expected
        Assert.areEqual(
            '<?xml version="1.0" encoding="UTF-8"?><soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:mdt="http://soap.sforce.com/2006/04/metadata"><soapenv:Header><mdt:SessionHeader><mdt:sessionId>'+ Wsdl.VAL_BEARER_TOKEN_HIDDEN_MESSAGE +'</mdt:sessionId></mdt:SessionHeader><mdt:CallOptions><mdt:client></mdt:client><mdt:defaultNamespace></mdt:defaultNamespace></mdt:CallOptions><mdt:AllOrNoneHeader><mdt:allOrNone>true</mdt:allOrNone></mdt:AllOrNoneHeader></soapenv:Header><soapenv:Body><mdt:readMetadata><type>CustomObject</type><fullNames>User</fullNames><fullNames>Account</fullNames></mdt:readMetadata></soapenv:Body></soapenv:Envelope>',
            metadataWsdl.getRequest().getBody()
        );
    }


    /**
     * METADATA WSDL - CREATE METADATA EXAMPLE
     */
    @IsTest
    static void testCreateMetadata(){

        // Create a new wsdl to the current org and set the soap action to 'createMetadata'
        Wsdl metadataWsdl = new MdtWsdl(URL.getOrgDomainUrl().toExternalForm(), Wsdl.VAL_BEARER_TOKEN_HIDDEN_MESSAGE, 'createMetadata')
            .addCredMetadata(
                'RemoteSiteSetting',
                new Map<String,Object>{
                    'fullName'    => 'Salesforce_Production_Login_Url',
                    'description' => 'Salesforce Production Login URL',
                    'disableProtocolSecurity' => false,
                    'isActive' => true,
                    'url' => 'https://login.salesforce.com'
                }
            )
            .addCredMetadata(
                'RemoteSiteSetting',
                new Map<String,Object>{
                    'fullName'    => 'Salesforce_Sandbox_Login_Url',
                    'description' => 'Salesforce Sandbox Login URL',
                    'disableProtocolSecurity' => false,
                    'isActive' => true,
                    'url' => 'https://test.salesforce.com'
                }
            )
            .addCredMetadata(
                'RemoteSiteSetting',
                new Map<String,Object>{
                    'fullName'    => 'My_Domain_Login_Url',
                    'description' => 'My Domain Login URL',
                    'disableProtocolSecurity' => false,
                    'isActive' => true,
                    'url' => URL.getOrgDomainUrl().toExternalForm()
                }
            )
            .setupRequest()
        ;

        // Check the body is as expected
        Assert.areEqual(
            '<?xml version="1.0" encoding="UTF-8"?><soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:mdt="http://soap.sforce.com/2006/04/metadata"><soapenv:Header><mdt:SessionHeader><mdt:sessionId>'+ Wsdl.VAL_BEARER_TOKEN_HIDDEN_MESSAGE +'</mdt:sessionId></mdt:SessionHeader><mdt:CallOptions><mdt:client></mdt:client><mdt:defaultNamespace></mdt:defaultNamespace></mdt:CallOptions><mdt:AllOrNoneHeader><mdt:allOrNone>true</mdt:allOrNone></mdt:AllOrNoneHeader></soapenv:Header><soapenv:Body><mdt:createMetadata><mdt:metadata xsi:type="mdt:RemoteSiteSetting"><fullName>Salesforce_Production_Login_Url</fullName><description>Salesforce Production Login URL</description><disableProtocolSecurity>false</disableProtocolSecurity><isActive>true</isActive><url>https://login.salesforce.com</url></mdt:metadata><mdt:metadata xsi:type="mdt:RemoteSiteSetting"><fullName>Salesforce_Sandbox_Login_Url</fullName><description>Salesforce Sandbox Login URL</description><disableProtocolSecurity>false</disableProtocolSecurity><isActive>true</isActive><url>https://test.salesforce.com</url></mdt:metadata><mdt:metadata xsi:type="mdt:RemoteSiteSetting"><fullName>My_Domain_Login_Url</fullName><description>My Domain Login URL</description><disableProtocolSecurity>false</disableProtocolSecurity><isActive>true</isActive><url>' + URL.getOrgDomainUrl().toExternalForm()+ '</url></mdt:metadata></mdt:createMetadata></soapenv:Body></soapenv:Envelope>',
            metadataWsdl.getRequest().getBody()
        );
    }


    /**
     * METADATA WSDL - UPDATE METADATA EXAMPLE
     */
    @IsTest
    static void testUpdateMetadata(){
        // Create a new wsdl to the current org and set the soap action to 'updateMetadata'
        Wsdl metadataWsdl = new MdtWsdl(URL.getOrgDomainUrl().toExternalForm(), Wsdl.VAL_BEARER_TOKEN_HIDDEN_MESSAGE , 'updateMetadata')
            .addCredMetadata(
                'RemoteSiteSetting',
                new Map<String,Object>{
                    'fullName'    => 'My_Domain_Login_Url',
                    'description' => 'My Domain Login URL - Updated',
                    'disableProtocolSecurity' => false,
                    'isActive' => true,
                    'url' => URL.getOrgDomainUrl().toExternalForm()
                }
            )
            .setupRequest()
        ;
      
        // Check the body is as expected
        Assert.areEqual(
            '<?xml version="1.0" encoding="UTF-8"?><soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:mdt="http://soap.sforce.com/2006/04/metadata"><soapenv:Header><mdt:SessionHeader><mdt:sessionId>'+ Wsdl.VAL_BEARER_TOKEN_HIDDEN_MESSAGE +'</mdt:sessionId></mdt:SessionHeader><mdt:CallOptions><mdt:client></mdt:client><mdt:defaultNamespace></mdt:defaultNamespace></mdt:CallOptions><mdt:AllOrNoneHeader><mdt:allOrNone>true</mdt:allOrNone></mdt:AllOrNoneHeader></soapenv:Header><soapenv:Body><mdt:updateMetadata><mdt:metadata xsi:type="mdt:RemoteSiteSetting"><fullName>My_Domain_Login_Url</fullName><description>My Domain Login URL - Updated</description><disableProtocolSecurity>false</disableProtocolSecurity><isActive>true</isActive><url>' + URL.getOrgDomainUrl().toExternalForm()+ '</url></mdt:metadata></mdt:updateMetadata></soapenv:Body></soapenv:Envelope>',
            metadataWsdl.getRequest().getBody()
        );
    }


    /**
     * METADATA WSDL - UPSERT METADATA EXAMPLE
     */
    @IsTest
    static void testUpsertMetadata(){
        // Create a new wsdl to the current org and set the soap action to 'upsertMetadata'
        Wsdl metadataWsdl = new MdtWsdl(URL.getOrgDomainUrl().toExternalForm(), Wsdl.VAL_BEARER_TOKEN_HIDDEN_MESSAGE ,'upsertMetadata')
            .addCredMetadata(
                'RemoteSiteSetting',
                new Map<String,Object>{
                    'fullName'        => 'My_Domain_Login_Url',
                    'description' => 'My Domain Login URL - Updated - Again',
                    'disableProtocolSecurity' => false,
                    'isActive' => true,
                    'url' => URL.getOrgDomainUrl().toExternalForm()
                }
            )
            .setupRequest()
        ;

        // Check the body is as expected
        Assert.areEqual(
            '<?xml version="1.0" encoding="UTF-8"?><soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:mdt="http://soap.sforce.com/2006/04/metadata"><soapenv:Header><mdt:SessionHeader><mdt:sessionId>'+ Wsdl.VAL_BEARER_TOKEN_HIDDEN_MESSAGE +'</mdt:sessionId></mdt:SessionHeader><mdt:CallOptions><mdt:client></mdt:client><mdt:defaultNamespace></mdt:defaultNamespace></mdt:CallOptions><mdt:AllOrNoneHeader><mdt:allOrNone>true</mdt:allOrNone></mdt:AllOrNoneHeader></soapenv:Header><soapenv:Body><mdt:upsertMetadata><mdt:metadata xsi:type="mdt:RemoteSiteSetting"><fullName>My_Domain_Login_Url</fullName><description>My Domain Login URL - Updated - Again</description><disableProtocolSecurity>false</disableProtocolSecurity><isActive>true</isActive><url>' + URL.getOrgDomainUrl().toExternalForm()+ '</url></mdt:metadata></mdt:upsertMetadata></soapenv:Body></soapenv:Envelope>',
            metadataWsdl.getRequest().getBody()
        );
    }


    /**
     * METADATA WSDL - DELETE METADATA EXAMPLE
     */
    @IsTest
    static void testDeleteMetadata(){
        
        // Create a new wsdl to the current org and set the soap action to 'deleteMetadata'
        Wsdl metadataWsdl = new MdtWsdl(URL.getOrgDomainUrl().toExternalForm(), Wsdl.VAL_BEARER_TOKEN_HIDDEN_MESSAGE ,'deleteMetadata')
            .setItemMetadataType('RemoteSiteSetting')
            .addItemMetadataFullName('Salesforce_Production_Login_Url')
            .addItemMetadataFullName('Salesforce_Sandbox_Login_Url')
            .addItemMetadataFullName('My_Domain_Login_Url')
            .setupRequest()
        ;

        // Check the body is as expected
        Assert.areEqual(
            '<?xml version="1.0" encoding="UTF-8"?><soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:mdt="http://soap.sforce.com/2006/04/metadata"><soapenv:Header><mdt:SessionHeader><mdt:sessionId>'+ Wsdl.VAL_BEARER_TOKEN_HIDDEN_MESSAGE +'</mdt:sessionId></mdt:SessionHeader><mdt:CallOptions><mdt:client></mdt:client><mdt:defaultNamespace></mdt:defaultNamespace></mdt:CallOptions><mdt:AllOrNoneHeader><mdt:allOrNone>true</mdt:allOrNone></mdt:AllOrNoneHeader></soapenv:Header><soapenv:Body><mdt:deleteMetadata><type>RemoteSiteSetting</type><fullNames>Salesforce_Production_Login_Url</fullNames><fullNames>Salesforce_Sandbox_Login_Url</fullNames><fullNames>My_Domain_Login_Url</fullNames></mdt:deleteMetadata></soapenv:Body></soapenv:Envelope>',
            metadataWsdl.getRequest().getBody()
        );
    }


    /**
     * METADATA WSDL - RENAME METADATA EXAMPLE
     */
    @IsTest
    static void testRenameMetadata(){

        // Create a new wsdl to the current org and set the soap action to 'renameMetadata'
        Wsdl metadataWsdl = new MdtWsdl(URL.getOrgDomainUrl().toExternalForm(), Wsdl.VAL_BEARER_TOKEN_HIDDEN_MESSAGE , 'renameMetadata')
            .setRenameMetadata(
                'RemoteSiteSetting',
                'Salesforce_Production_Login_Url',
                'Salesforce_Production_Login_Url'
            )
            .setRenameMetadata(
                'RemoteSiteSetting',
                'Salesforce_Sandbox_Login_Url',
                'Salesforce_Sandbox_Url'
            )
            .setClientId('ABC123')
            .setDefaultNamespace('lwt')
            .setupRequest()
        ;

        // Check the body is as expected
        Assert.areEqual(
            '<?xml version="1.0" encoding="UTF-8"?><soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:mdt="http://soap.sforce.com/2006/04/metadata"><soapenv:Header><mdt:SessionHeader><mdt:sessionId>' + Wsdl.VAL_BEARER_TOKEN_HIDDEN_MESSAGE + '</mdt:sessionId></mdt:SessionHeader><mdt:CallOptions><mdt:client>ABC123</mdt:client><mdt:defaultNamespace>lwt</mdt:defaultNamespace></mdt:CallOptions><mdt:AllOrNoneHeader><mdt:allOrNone>true</mdt:allOrNone></mdt:AllOrNoneHeader></soapenv:Header><soapenv:Body><mdt:renameMetadata><type>RemoteSiteSetting</type><oldFullName>Salesforce_Sandbox_Login_Url</oldFullName><newFullName>Salesforce_Sandbox_Url</newFullName></mdt:renameMetadata></soapenv:Body></soapenv:Envelope>',
            metadataWsdl.getRequest().getBody()
        );
    }
}