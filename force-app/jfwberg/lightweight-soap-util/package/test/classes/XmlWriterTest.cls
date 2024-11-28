/**
 * @author         Justus van den Berg (jfwberg@gmail.com)
 * @date           November 2024
 * @copyright      (c) 2024 Justus van den Berg
 * @license        MIT (See LICENSE file in the project root)
 * @description    Test class for the XmlWriter class
 */
@IsTest
private with sharing class XmlWriterTest {
    
    @IsTest
	static void testXmlFromObjectMap(){
		// Assertion variables
        String result;

        // Run test
        Test.startTest();
       
        // Test data
        Map<String,Object> connectedAppMetadataMap = new Map<String,Object>{
            'ConnectedApp'	=> new Map<String,Object> {
                'fullName'		=> 'Current_Org',
                'label'			=> 'Current Org',
                'description'	=> 'A connected App to the current org\'s for the use of API that are used by Lightning (Web) components',
                'contactEmail'	=> 'info@aloha-workshop.com',
                'oauthConfig'	=> new Map<String,Object> {
                    'callbackUrl'				=> 'http://localhost',
                    'certificate'				=> '[CERT_DATA]',
                    'isAdminApproved'			=> true,
                    'isConsumerSecretOptional'	=> false,
                    'isIntrospectAllTokens'		=> false,
                    'scopes'					=> new Object[]{
                        'Api',
                        'RefreshToken'
                    }
                },
                'oauthPolicy' => new Map<String,Object>{
                    'ipRelaxation'		=> 'ENFORCE',
                    'refreshTokenPolicy'=> 'infinite'
                },
                'profileName' => new Object[]{
                    'System Administrator'
                },
                'permissionSetName' => new Object[]{
                    'Current Org'
                },
                'ipRanges' => new Object[]{
                    new Map<String,Object>{
                        'start'			=>'10.0.0.0',
                        'end'			=>'10.255.255.255',
                        'description'  => 'Salesforce Internal IP Address range, needs white listed for calling REST Api'
                    }
                },
                'attributes' => new Object[]{
                    new Map<String,Object>{
                        'key'		=>'validationKey',
                        'formula'	=>'\'EMTX1\''
                    },
                    new Map<String,Object>{
                        'key'		=>'verificationKey',
                        'formula'	=>'\'EMTX2\''
                    }
                }
            }       
        };

        // Existing or New writer example
        XmlStreamWriter w = new XmlStreamWriter();
        XmlWriter.write(null, w, connectedAppMetadataMap);
        result = w.getXmlString();
        
        Test.stopTest();

		// Validate expected output
        Assert.areEqual(
			'<ConnectedApp><fullName>Current_Org</fullName><label>Current Org</label><description>A connected App to the current org\'s for the use of API that are used by Lightning (Web) components</description><contactEmail>info@aloha-workshop.com</contactEmail><oauthConfig><callbackUrl>http://localhost</callbackUrl><certificate>[CERT_DATA]</certificate><isAdminApproved>true</isAdminApproved><isConsumerSecretOptional>false</isConsumerSecretOptional><isIntrospectAllTokens>false</isIntrospectAllTokens><scopes>Api</scopes><scopes>RefreshToken</scopes></oauthConfig><oauthPolicy><ipRelaxation>ENFORCE</ipRelaxation><refreshTokenPolicy>infinite</refreshTokenPolicy></oauthPolicy><profileName>System Administrator</profileName><permissionSetName>Current Org</permissionSetName><ipRanges><start>10.0.0.0</start><end>10.255.255.255</end><description>Salesforce Internal IP Address range, needs white listed for calling REST Api</description></ipRanges><attributes><key>validationKey</key><formula>\'EMTX1\'</formula></attributes><attributes><key>verificationKey</key><formula>\'EMTX2\'</formula></attributes></ConnectedApp>',
			result,
            'Unexpected XML string'
		);
    }


    @IsTest
    static void testXmlFromObjectList(){
        
        // Assertion variables
        String result;

        Test.startTest();

        // List holding the sObject types
        Object[] objectMap = new Object[]{};

        // Populate sObject type map
        for(String sObjectType : new String[]{'Account','Case','Contact','Opportunity'}){
            objectMap.add(
                new Map<String,Object>{
                    'sObjectType' => sObjectType
                }
            );
        }
        
        Test.stopTest();

        // Existing or New writer example
        XmlStreamWriter w = new XmlStreamWriter();
        XmlWriter.write(null, w, objectMap);
        result = w.getXmlString();
        
        // Validate expected output
        Assert.areEqual(
            '<sObjectType>Account</sObjectType><sObjectType>Case</sObjectType><sObjectType>Contact</sObjectType><sObjectType>Opportunity</sObjectType>',
            result,
            'Unexpected XML string'
        );
    }


    @IsTest
    static void testXmlFromObjectListWtihNamespace(){
        
        // Assertion variables
        String result;

        Test.startTest();

        // List holding the sObject types
        Object[] objectMap = new Object[]{};

        // Populate sObject type map
        for(String sObjectType : new String[]{'Account','Case','Contact','Opportunity'}){
            objectMap.add(
                new Map<String,Object>{
                    'sObjectType' => sObjectType
                }
            );
        }

        // Write stream with namespace
        XmlStreamWriter w = new XmlStreamWriter();
        XmlWriter.write('dns', w, objectMap);
        result = w.getXmlString();
        
        Test.stopTest();
        
        // Validate expected output
        Assert.areEqual(
            '<dns:sObjectType>Account</dns:sObjectType><dns:sObjectType>Case</dns:sObjectType><dns:sObjectType>Contact</dns:sObjectType><dns:sObjectType>Opportunity</dns:sObjectType>',
            result,
            'Unexpected XML string'
        );
    }
}