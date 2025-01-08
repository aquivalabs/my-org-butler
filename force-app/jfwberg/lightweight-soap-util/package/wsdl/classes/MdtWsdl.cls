/**
* @author         Justus van den Berg (jfwberg@gmail.com)
* @date           November 2024
* @copyright      (c) 2024 Justus van den Berg
* @license        MIT (See LICENSE file in the project root)
* @description    Class that contains a set of Salesforce SOAP API  Utilities
* @note           This class is to be used in a managed package and contains public  methods that
*                 should be made public or private in org based implementations or unlocked
*                 packages.
*                 Can be modified to make smaller in your own implementation
*/
@SuppressWarnings('PMD.EmptyStatementBlock, PMD.ExcessivePublicCount')
public  with sharing class MdtWsdl extends Wsdl implements Wsdl.IWsdl{


    /** **************************************************************************************************** **
     **                                          PRIVATE CONSTANTS                                           **
     ** **************************************************************************************************** **/
    // Specific SOAP API configuration
    private static final String VAL_DEFAULT_SOAP_ACTION	= 'listMetadata';
    private static final String VAL_METADATA_SERVICE_URL= '/services/Soap/m/';
    private static final String VAL_SERVICE_XML_NS_PFX	= 'mdt';
    private static final String VAL_SERVICE_XML_NS_URL	= 'http://soap.sforce.com/2006/04/metadata';

    // Messages
    private static final String MSG_ITEM_TYPE_REQUIRED	            = 'No metadata type set yet. Please set the metadata by using the "setItemMetadataType" method beore adding fullNames';
    private static final String MSG_INVALID_SOAP_BODY_TYPE_MAPPING	= 'Invalid SOAP BODY TYPE mapped to SOAP ACTION  in the SOAP ACTION MAP';


    /** **************************************************************************************************** **
     **                                          PRIVATE VARIABLES                                           **
     ** **************************************************************************************************** **/
    // All or none header flag
    private transient Boolean allOrNone = true;
    
    // Object representing the different soap request body types
    private transient ListMetadata		listMetadata;
    private	transient ItemMetadata		itemMetadata;
    private transient CredMetadata		credMetadata;
    private transient RenameMetadata	renameMetadata;
    
    
    /** **************************************************************************************************** **
     **                                             CONSTRUCTORS                                             **
     ** **************************************************************************************************** **/
    // Constructor for default soap action
    public  MdtWsdl(String soapAction){
        this.setupMetadataService( String.isBlank(soapAction) ? MdtWsdl.VAL_DEFAULT_SOAP_ACTION : soapAction);
        this.setupMyDomain(null, null);
    }

    // Constructor for default soap action
    public  MdtWsdl(String namedCredentialName, String soapAction){
        this.setupMetadataService( String.isBlank(soapAction) ? MdtWsdl.VAL_DEFAULT_SOAP_ACTION : soapAction);
        this.setupNamedCredential(namedCredentialName);
    }

    // Constructor for user specified soap action
    public  MdtWsdl(String myDomainUrl, String sessionId, String soapAction){
        this.setupMetadataService(String.isBlank(soapAction) ? MdtWsdl.VAL_DEFAULT_SOAP_ACTION : soapAction);
        this.setupMyDomain(myDomainUrl, sessionId);
    }


    /** **************************************************************************************************** **
     **                                          CONSTRUCTOR LOGIC                                           **
     ** **************************************************************************************************** **/
    private void setupMetadataService(String soapAction){
        
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
     * @description Method to setup the endpoint url for this service
     *              !! Interface Method !!
     */
    public void setApiServiceEndpoint(){
        this.setApiServiceEndpoint(MdtWsdl.VAL_METADATA_SERVICE_URL);
    }


    /**
     * @description Method to setup the XML namespace for this service
     *              !! Interface Method !!
     */
    public void setServiceNamespaceDetails(){
        this.setServiceNamespacePrefix(MdtWsdl.VAL_SERVICE_XML_NS_PFX);
        this.setServiceNamespace(MdtWsdl.VAL_SERVICE_XML_NS_URL);
    }


    /**
     * @description Method to setup the soap action mapping for this service
     *              !! Interface Method !!
     */
    public void setSoapActionMap(){
        this.setSoapActionMap(new Map<String, String>{
            'describeMetadata'	=>	'empty',
            'listMetadata'		=>	'list',
            'readMetadata'		=>	'item',
            'createMetadata'	=>	'cred',
            'updateMetadata'	=>	'cred',
            'renameMetadata'	=>	'rename',
            'upsertMetadata'	=>	'cred',
            'deleteMetadata'	=>	'item'
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
        this.setAllOrNoneHeader();
        
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
            when 'empty' {} 
            when 'list' {
                this.writeListSoapBody(w);
            }   
            when 'item' {
                this.writeItemSoapBody(w);
            }
            when 'cred' {
                this.writeCredSoapBody(w);
            }
            when 'rename' {
                this.writeRenameSoapBody(w);
            }
            when else {
                throw new Wsdl.SoapUtilException(MdtWsdl.MSG_INVALID_SOAP_BODY_TYPE_MAPPING);
            }
        }
    }


    /** **************************************************************************************************** **
     **                                           PRIVATE SETTERS                                            **
     ** **************************************************************************************************** **/
    /**
     * @description Method to write the all or none headers
     */
    private void setAllOrNoneHeader(){
        this.getSoapHeaderMap().put(
            'AllOrNoneHeader', new Map<String,Object>{
                'allOrNone' => (this.allOrNone!=null) ? String.valueOf(this.allOrNone) : 'true'
            }
        );
    }


    /** **************************************************************************************************** **
     **                                           public  SETTERS                                             **
     ** **************************************************************************************************** **/
    /**
     * @description Method to set all or none
     */
    public  MdtWsdl setAllOrNone(Boolean allOrNone){
        this.allOrNone = allOrNone;
        return this;
    } 

    
    /**
     *	@description Overload method to add a metadata type without a folder to the list metadata map
     */
    public  MdtWsdl addListMetadata(String metadataType){
        this.addListMetadata(metadataType,null);
        return this;
    }
    
    
    /**
     *	@description Method to add a metadata type with a folder to the list metadata map
     */
    public  MdtWsdl addListMetadata(String metadataType, String folder){
        if(this.listMetadata == null){
            this.listMetadata = new ListMetadata();
        }
        this.listMetadata.addQuery(folder,metadataType);
        return this;
    }

    
    /**
     * @description Method to add the type of the meta data to ITEM
     *              Will reset the items as you should start with this first
     */
    public  MdtWsdl setItemMetadataType(String typeName){
        this.itemMetadata = new ItemMetadata(typeName);
        return this;
    }
    

    /**
     * @description Method to add a ITEM metadata type
     */
    public  MdtWsdl addItemMetadataFullName(String fullName){
        if(this.itemMetadata == null){
            throw new Wsdl.SoapUtilException(MSG_ITEM_TYPE_REQUIRED);
        }
        this.itemMetadata.addFullName(fullName);
        return this;
    }


    /**
     * @description Method to add a CRED Metadata type
     */
    public  MdtWsdl addCredMetadata(String metadataType, Map<String,Object> attributeMap){
        if(this.credMetadata == null){
            this.credMetadata = new CredMetadata();
        }
        this.credMetadata.addMetadata(metadataType,attributeMap);
        return this;
    }


    /**
     * @description Method to add a RENAME Metadata type
     */
    public  MdtWsdl setRenameMetadata(String metadataType, String oldFullName, String newFullName){
        if(this.renameMetadata == null){
            this.renameMetadata = new RenameMetadata();
        }
        this.renameMetadata.setValues(metadataType,oldFullName,newFullName);
        return this;
    }


    /** **************************************************************************************************** **
     **                                      PRIVATE XML WRITER METHODS                                      **
     ** **************************************************************************************************** **/
    /**
     * @description Method to write the LIST soap body
     */
    private void writeListSoapBody(XmlStreamWriter w){
        
        // Prevent null pointers
        if(this.listMetadata?.queries == null){
            return;
        }
        
        // Write all metadata types that occur in the metadata map, XML is build per metadata type
        for(ListMetadataQuery lmq : this.listMetadata.queries){
            
            // Write the list queries body
            XmlWriter.write(null,w,
                new Map<String,Object>{
                    'queries' => new Map<String,Object>{
                        'folder'=>	lmq.folder,
                        'type'	=>	lmq.type
                    }
                }
            );
        }
    }


    /**
     * @description Method to write the READ soap body
     */
    private void writeItemSoapBody(XmlStreamWriter w){
        XmlWriter.write(null,w,
            new Map<String,Object>{
                'type' => this.itemMetadata.type
            }
        );

        // Write all metadata types that occur in the metadata map, XML is build per metadata type
        for(String fullName : this.itemMetadata.fullNames){
            XmlWriter.write(null,w,
                new Map<String,Object>{
                    'fullNames' => fullName
                }
            );
        }
    }


    /**
     * @description Method to write the CRED soap body
     */
    private void writeCredSoapBody(XmlStreamWriter w){
        
        // Write all metadata types that occur in the metadata map, XML is build per metadata type
        for(Metadata metadata : this.credMetadata.metadataList){
            w.writeStartElement(this.getServiceNamespacePrefix(), 'metadata', '');
            w.writeAttribute(null,null,'xsi:type', this.getServiceNamespacePrefix() + ':' + metadata.type);
            XmlWriter.write(null,w,metadata.attributeMap);
            w.writeEndElement();
        }
    }


    /**
     * @description Method to write the RENAME soap body
     */
    private void writeRenameSoapBody(XmlStreamWriter w){
        XmlWriter.write(null,w,
            new Map<String,Object>{
                'type'			=>	this.renameMetadata.type,
                'oldFullName'	=>	this.renameMetadata.oldFullName,
                'newFullName'	=>	this.renameMetadata.newFullName
            }
        );
    }


    /* ** ******************************************************************** ** * 
     * **                           PRIVATE CLASSES                             ** * 
     * ** ******************************************************************** ** */
    /**
     * @description Class representing a list metadata soap body
     */
    private class ListMetadata{
        public ListMetadataQuery[] queries;
        
        public ListMetadata(){
            this.queries = new ListMetadataQuery[]{};
        }
        
        public void addQuery(String folder,String type){
            this.queries.add(new ListMetadataQuery(folder,type));
        }
    }


    /**
     * @description Class representing a LIST metadata Query
     */
    private class ListMetadataQuery{
        public String folder;
        public String type;
        
        public ListMetadataQuery(String folder,String type){
            this.folder = folder;
            this.type	= type;
        }
    }


    /**
     * @description Class representing a READ metadata soap body
     */
    private class ItemMetadata{
        public String type;
        public String[] fullNames;
        
        public ItemMetadata(String typeName){
            this.type = typeName;
            this.fullNames = new String[]{};
        }
        
        public void addFullName(String value){
            this.fullNames.add(value);
        }
    }


    /**
     * @description Class representing a CRED metadata soap body
     */
    private class CredMetadata{
        public Metadata[] metadataList;
        
        public CredMetadata(){
            this.metadataList = new Metadata[]{};
        }
        
        public void addMetadata(String type,Map<String,Object> attributeMap){
            this.metadataList.add(
                new Metadata(
                    type,attributeMap
                )
            );
        }
    }


    /**
     * @description Class representing a metadata item
     */
    private class Metadata{
        public String             type;
        public Map<String,Object> attributeMap;
        
        Metadata(String type, Map<String, Object> attributeMap){
            this.type = type;
            this.attributeMap = attributeMap;
        }
    }


    /**
     * @description Class representing a RENAME metadata soap body
     */
    private class RenameMetadata{
        public String type;
        public String oldFullName;
        public String newFullName;

        public void setValues(String type, String oldFullName, String newFullName){
            this.type = type;
            this.oldFullName = oldFullName;
            this.newFullName = newFullName;
        }
    }
}