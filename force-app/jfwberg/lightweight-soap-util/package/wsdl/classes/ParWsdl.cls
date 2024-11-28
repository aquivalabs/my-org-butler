/**
* @author         Justus van den Berg (jfwberg@gmail.com)
* @date           November 2024
* @copyright      (c) 2024 Justus van den Berg
* @license        MIT (See LICENSE file in the project root)
* @description    Class that contains a set of Salesforce SOAP API  Utilities
* @note           This class is to be used in a managed package and contains Global methods that
*                 should be made public or private in org based implementations or unlocked
*                 packages.
*                 Can be modified to make smaller in your own implementation
*/
@SuppressWarnings('PMD.AvoidGlobalModifier, PMD.EmptyStatementBlock')
global with sharing class ParWsdl extends Wsdl implements Wsdl.IWsdl{

    /** **************************************************************************************************** **
     **                                          PRIVATE CONSTANTS                                           **
     ** **************************************************************************************************** **/
    private static final String VAL_DEFAULT_SOAP_ACTION	= 'getUserInfo';
    private static final String VAL_METADATA_SERVICE_URL= '/services/Soap/u/';
    private static final String VAL_SERVICE_XML_NS_PFX	= 'urn';
    private static final String VAL_SERVICE_XML_NS_URL	= 'urn:partner.soap.sforce.com';

    // Messages
    private static final String MSG_INVALID_SOAP_BODY_TYPE_MAPPING	= 'Invalid SOAP BODY TYPE mapped to SOAP ACTION  in the SOAP ACTION MAP';

    
    /** **************************************************************************************************** **
     **                                          PRIVATE VARIABLES                                           **
     ** **************************************************************************************************** **/
    // For user related soap actions
    private String userId;
    private String username;
    private String password;

    // For describe related soap actions
    private String   sObjectType;
    private String[] sObjectTypes = new String[]{};
    

    /** **************************************************************************************************** **
     **                                             CONSTRUCTORS                                             **
     ** **************************************************************************************************** **/
    // Constructor for default soap action
    global ParWsdl(String soapAction){
        this.setupPartnerApiService( String.isEmpty(soapAction) ? VAL_DEFAULT_SOAP_ACTION : soapAction);
        this.setupMyDomain(null, null);
    }

    // Constructor for default soap action
    global ParWsdl(String namedCredentialName, String soapAction){
        this.setupPartnerApiService( String.isEmpty(soapAction) ? VAL_DEFAULT_SOAP_ACTION : soapAction);
        this.setupNamedCredential(namedCredentialName);
    }

    // Constructor for user specified soap action
    global ParWsdl(String myDomainUrl, String sessionId, String soapAction){
        this.setupPartnerApiService(String.isEmpty(soapAction) ? VAL_DEFAULT_SOAP_ACTION : soapAction);
        this.setupMyDomain(myDomainUrl, sessionId);
    }


    /** **************************************************************************************************** **
     **                                          CONSTRUCTOR LOGIC                                           **
     ** **************************************************************************************************** **/
    private void setupPartnerApiService(String soapAction){
        
        // Set the service endpoint for this API
        this.setApiServiceEndpoint();

        // Setup the namespace for this specific service
        this.setServiceNamespaceDetails(); 

        // Setup the map met allowed soapactions
        this.setSoapActionMap();

        // Set the default soap action
        this.setSoapAction(soapAction);	
    }


    /** **************************************************************************************************** **
     **                                          INTERFACE METHODS                                           **
     ** **************************************************************************************************** **/
    /**
     * @description Method to setup the namespace for this service
     *              !! Interface Method !!
     */
    public void setApiServiceEndpoint(){
        this.setApiServiceEndpoint(VAL_METADATA_SERVICE_URL);
    }


    /**
     * @description Method to setup the namespace for this service
     *              !! Interface Method !!
     */
    public void setServiceNamespaceDetails(){
        this.setServiceNamespacePrefix(VAL_SERVICE_XML_NS_PFX);
        this.setServiceNamespace(VAL_SERVICE_XML_NS_URL);
    }


    /**
     * @description Method to setup the soap action mapping for this service
     *              !! Interface Method !!
     */
    public void setSoapActionMap(){
        this.setSoapActionMap(new Map<String, String>{
            'login'				=>	'login',
            'logout'			=>	'logout',
            'getUserInfo'		=>	'getUserInfo',
            'setPassword'		=>	'setPassword',
            'resetPassword'		=>	'resetPassword',
            'describeGlobal'	=>	'describeGlobal',
            'describeSObject'	=>	'describeSObject',
            'describeSObjects'	=>	'describeSObjects'
        });
    }


    /** **************************************************************************************************** **
     **                                           OVERRIDE METHODS                                           **
     ** **************************************************************************************************** **/
    /**
     * @description Method to generate the SOAP Header for the Metadata SOAP request
     *              !! override !!
     */
    public override void writeSoapHeaderContent(XmlStreamWriter w){
        
        // Write the soap body based on the soap action type mapping
        switch on this.getSoapActionMap().get(this.getSoapAction()){
            when 'login' {
                this.setCallOptionsHeader();
            } 
            when else {
                this.setSessionHeader();
                this.setCallOptionsHeader();
            }
        }

        // Write header content
        XmlWriter.write(
            this.getServiceNamespacePrefix(),
            w,
            this.getSoapHeaderMap()
        );
    }


    /**
     * @description Method to generate the XML Body for the Metadata SOAP request
     *              !! override !!
     */
    public override void writeSoapBodyContent(XmlStreamWriter w){
        
        // Write the soap body based on the soap action type mapping
        switch on this.getSoapActionMap().get(this.getSoapAction()){
            when 'login' {
                this.writeLoginSoapBody(w);
            } 
            when 'logout'{}
            when 'getUserInfo'{}
            when 'describeGlobal'{}
            when 'describeSObject'{
                this.writeDescribeSObjectSoapBody(w);
            }
            when 'describeSObjects'{
                this.writeDescribeSObjectsSoapBody(w);
            }
            when 'setPassword'{
                this.writeSetPasswordSoapBody(w);
            }
            when 'resetPassword'{
                this.writeResetPasswordSoapBody(w);
            }
            when else {
                throw new Wsdl.SoapUtilException(MSG_INVALID_SOAP_BODY_TYPE_MAPPING);
            }
        }
    }


    /** **************************************************************************************************** **
     **                                           GLOBAL SETTERS                                             **
     ** **************************************************************************************************** **/
    global ParWsdl setUserId(String userId){
        this.userId = userId;
        return this;
    }

    global ParWsdl setUsername(String username){
        this.username = username;
        return this;
    }

    global ParWsdl setPassword(String password){
        this.password = password;
        return this;
    }

    global ParWsdl setSObjectType(String sObjectType){
        this.sObjectType = sObjectType;
        return this;
    }

    global ParWsdl addSObjectType(String sObjectType){
        this.sObjectTypes.add(sObjectType);
        return this;
    }


    /** **************************************************************************************************** **
     **                                      PRIVATE XML WRITER METHODS                                      **
     ** **************************************************************************************************** **/
    private void writeLoginSoapBody(XmlStreamWriter w){
        // Write the rename soap body
        XmlWriter.write(
            this.getServiceNamespacePrefix(),
            w,
            new Map<String,Object>{
                'username' => this.username,
                'password' => this.password
            }
        );
    }
    

    private void writeDescribeSObjectSoapBody(XmlStreamWriter w){
        // Write the rename soap body
        XmlWriter.write(
            this.getServiceNamespacePrefix(),
            w,
            new Map<String,Object>{
                'sObjectType' => this.sObjectType
            }
        );
    }


    private void writeDescribeSObjectsSoapBody(XmlStreamWriter w){
        
        // List holding the sObject types
        List<Map<String,Object>> sObjectTypeMap = new List<Map<String,Object>>();

        // Check there are types and add them all
        if(this.sObjectTypes != null){
            for(String sObjectType : this.sObjectTypes){
                sObjectTypeMap.add(
                    new Map<String,Object>{
                        'sObjectType' => sObjectType
                    }
                );
            }
            // Write the soap body
            XmlWriter.write(
                this.getServiceNamespacePrefix(),
                w,
                sObjectTypeMap
            );
        }
    }


    private void writeSetPasswordSoapBody(XmlStreamWriter w){
        XmlWriter.write(
            this.getServiceNamespacePrefix(),
            w,
            new Map<String,Object>{
                'userId'	=>	this.userId,
                'password'	=>	this.password
            }
        );
    }


    private void writeResetPasswordSoapBody(XmlStreamWriter w){
        XmlWriter.write(
            this.getServiceNamespacePrefix(),
            w,
            new Map<String,Object>{
                'userId' =>	this.userId
            }
        );
    }
}