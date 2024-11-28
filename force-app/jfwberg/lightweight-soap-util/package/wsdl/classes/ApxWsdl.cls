/**
 * @author         Justus van den Berg (jfwberg@gmail.com)
 * @date           November 2024
 * @copyright      (c) 2024 Justus van den Berg
 * @license        MIT (See LICENSE file in the project root)
 * @description    Class that contains a set of Salesforce SOAP API Utilities
 * @note           This class is to be used in a managed package and contains Global methods that
 *                 should be made public or private in org based implementations or unlocked
 *                 packages.
 *                 Can be modified to make smaller in your own implementation
 */
@SuppressWarnings('PMD.AvoidGlobalModifier')
global with sharing class ApxWsdl extends Wsdl implements Wsdl.IWsdl{

    /** **************************************************************************************************** **
     **                                          PRIVATE VARIABLES                                           **
     ** **************************************************************************************************** **/
    // Code to be executed by execute anonymous, set a default
    private String code;

    // Include correct logging level in debug statements in orde to show up 
    // like System.debug(LoggingLevel.Error,'Output text in here');
    // This prevents clogging up your debug logs when you're actually debugging
    private String logLevel;
    private String logCategory;
    
    // List of apex scripts for use with compile functions
    private String[] scripts = new String[]{};


    /** **************************************************************************************************** **
     **                                          PRIVATE CONSTANTS                                           **
     ** **************************************************************************************************** **/
    // Specific SOAP API configuration
    private static final String VAL_DEFAULT_SOAP_ACTION	= 'executeAnonymous';
    private static final String VAL_METADATA_SERVICE_URL= '/services/Soap/s/';
    private static final String VAL_SERVICE_XML_NS_PFX	= 'apex';
    private static final String VAL_SERVICE_XML_NS_URL	= 'http://soap.sforce.com/2006/08/apex';

    // Logging defaults
    private static final String VAL_DEFAULT_LOG_LEVEL	= 'ERROR';
    private static final String VAL_DEFAULT_LOG_CATEGORY= 'APEX_CODE';

    // Example code for execution that can be reused
    private static final String VAL_EXAMPLE_APEX_CODE	= 'System.debug(12345);';

    // (Error) messages
    private static final String MSG_CODE_CANNOT_BE_BLANK= 'Code or Script body cannot be blank';
    private static final String MSG_INVALID_LOG_LEVEL	= 'Invalid log level "{0}", valid log levels are: "NONE","ERROR","WARN","INFO","DEBUG","FINE","FINER","FINEST"';
    private static final String MSG_INVALID_LOG_CATEGORY= 'Invalid log category "{0}", valid log categories are: "DATABASE","WORKFLOW","NBA","VALIDATION","CALLOUT","APEX_CODE","APEX_PROFILING","VISUALFORCE","SYSTEM"';
    private static final String MSG_INVALID_SOAP_BODY_TYPE_MAPPING	= 'Invalid SOAP BODY TYPE mapped to SOAP ACTION  in the SOAP ACTION MAP';

    // Set of allowed log levels, set so we can check later
    private static final Set<String> VAL_LOG_LEVELS = new Set<String> {
        'NONE','ERROR','WARN','INFO','DEBUG','FINE','FINER','FINEST'
    };

    // Set of allowed log categories, set so we can check later
    private static final Set<String> VAL_LOG_CATEGORIES = new Set<String> {
        'DATABASE','WORKFLOW','NBA','VALIDATION','CALLOUT','APEX_CODE','APEX_PROFILING','VISUALFORCE','SYSTEM'
    };


    /** **************************************************************************************************** **
     **                                             CONSTRUCTORS                                             **
     ** **************************************************************************************************** **/
    // Constructor for default soap action
    global ApxWsdl(String soapAction){
        this.setupApexApiService( String.isEmpty(soapAction) ? VAL_DEFAULT_SOAP_ACTION : soapAction);
        this.setupMyDomain(null, null);
    }

    // Constructor for default soap action
    global ApxWsdl(String namedCredentialName, String soapAction){
        this.setupApexApiService( String.isEmpty(soapAction) ? VAL_DEFAULT_SOAP_ACTION : soapAction);
        this.setupNamedCredential(namedCredentialName);
    }

    // Constructor for user specified soap action
    global ApxWsdl(String myDomainUrl, String sessionId, String soapAction){
        this.setupApexApiService(String.isEmpty(soapAction) ? VAL_DEFAULT_SOAP_ACTION : soapAction);
        this.setupMyDomain(myDomainUrl, sessionId);
    }
    

    /** **************************************************************************************************** **
     **                                          CONSTRUCTOR LOGIC                                           **
     ** **************************************************************************************************** **/
    private void setupApexApiService(String soapAction){
        
        // Set the service endpoint for this API
        this.setApiServiceEndpoint();

        // Setup the namespace for this specific service
        this.setServiceNamespaceDetails();

        // Setup the map met allowed soap actions !! Must run before setting soap action !!
        this.setSoapActionMap();

        // Set the default soap action
        this.setSoapAction(soapAction);

        // Set some example code by default
        this.setCode(VAL_EXAMPLE_APEX_CODE);

        // Set default log level
        this.setLogLevel(VAL_DEFAULT_LOG_LEVEL);
        
        // Set default log category
        this.setLogCategory(VAL_DEFAULT_LOG_CATEGORY);
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
            'executeAnonymous'	=>	'executeAnonymous',
            'compileClasses'	=>	'scripts',
            'compileTriggers'	=>	'scripts'
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
        
        // Write default header content
        this.setSessionHeader();
        this.setCallOptionsHeader();
        
        // Write class specific content
        this.setDebuggingHeader();
        
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
            when 'executeAnonymous' {
                this.writeExecuteAnonymousSoapBody(w);
            } 
            when 'scripts' {
                this.writeScriptsSoapBody(w);
            }
            when else {
                throw new Wsdl.SoapUtilException(MSG_INVALID_SOAP_BODY_TYPE_MAPPING);
            }
        }
    }


    /** **************************************************************************************************** **
     **                                           PRIVATE SETTERS                                            **
     ** **************************************************************************************************** **/
    /**
      * @description Method to write the Debugging Header
      */
    private void setDebuggingHeader(){
        this.getSoapHeaderMap().put(
            'DebuggingHeader', new Map<String,Object>{
                'categories' 	=> new Map<String,Object>{
                    'category' 	=> this.logCategory,
                    'level'		=> this.logLevel
                },
                'debugLevel' => 'NONE'
            }
        );
    }

    /** **************************************************************************************************** **
     **                                           GLOBAL SETTERS                                             **
     ** **************************************************************************************************** **/
    global ApxWsdl setCode(String code){
        if(String.isBlank(code)){
            throw new Wsdl.SoapUtilException(MSG_CODE_CANNOT_BE_BLANK); 
        }
        this.code = code;
        return this;
    }


    global ApxWsdl setLogLevel(String logLevel){
        if(!VAL_LOG_LEVELS.contains(logLevel)){
            throw new Wsdl.SoapUtilException(String.format(MSG_INVALID_LOG_LEVEL, new String[]{logLevel}));
        }
        this.logLevel = logLevel;
        return this;
    }

    
    global ApxWsdl setLogCategory(String logCategory){
        if(!VAL_LOG_CATEGORIES.contains(logCategory)){
            throw new Wsdl.SoapUtilException(String.format(MSG_INVALID_LOG_CATEGORY, new String[]{logCategory}));
            
        }
        this.logCategory = logCategory;
        return this;
    }


    global ApxWsdl addScript(String script){
        if(String.isBlank(script)){
            throw new Wsdl.SoapUtilException(MSG_CODE_CANNOT_BE_BLANK);
        }
        this.scripts.add(script);
        return this;
    }


    /** **************************************************************************************************** **
     **                                      PRIVATE XML WRITER METHODS                                      **
     ** **************************************************************************************************** **/
    private void writeExecuteAnonymousSoapBody(XmlStreamWriter w){
        XmlWriter.write(
            null,
            w,
            new Map<String,Object>{
                'String' =>	this.code
            }
        );
    }

    private void writeScriptsSoapBody(XmlStreamWriter w){
        for(String script : this.scripts){
            XmlWriter.write(
                null,
                w,
                new Map<String,Object>{
                    'scripts' => script
                }
            );
        }
    }
}