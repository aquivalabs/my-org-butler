// PMD False Positives: 
// - Only global invocables are seen in installed org
@SuppressWarnings('PMD.AvoidGlobalModifier')
global with sharing class UseMetadataApi {

    public static HttpResponse mockedResponse = null;
    
    @InvocableMethod(label='MyOrgButler: Use Metadata API' description='Describe, list, reads, creates, updates, renames or deletes metadata using an Apex Wrapper lib. Most actions require a Metadata type given its name and attribute map as JSON. Uses an MDAPI Apex wrapper.')
    global static List<Output> execute(List<MetadataDescription> descriptions) {
        List<Output> result = new List<Output>();

        for(MetadataDescription metadata : descriptions) {
            try {
                Wsdl action = actionFor(metadata)
                                .setMockResponse(mockedResponse)
                                .call()
                                .handleErrors();

                result.add(new Output( action.getResponse()?.getBody() ));
            }
            catch(Wsdl.SoapApiException ex) {
                throw new ApplicationException('Deploy Metadata Action failed: ' + ex.getMessage(), ex);
            }
        }
            
        return result;
    }

    // PRIVATE

    private static Wsdl actionFor(MetadataDescription metadata) {
        Wsdl result = null;
    
        switch on metadata.soapAction {
            when 'describeMetadata' {
                result = new MdtWsdl(metadata.soapAction);
            }
            when 'listMetadata' {
                result = new MdtWsdl(metadata.soapAction)
                                .setAllOrNone(true)
                                .addListMetadata(metadata.typeName);
            }
            when 'readMetadata' {
                result = new MdtWsdl(metadata.soapAction)
                                .setItemMetadataType(metadata.typeName)
                                .addItemMetadataFullName(metadata.fullName);
            }
            when 'createMetadata', 'updateMetadata', 'upsertMetadata' {
                result = new MdtWsdl(metadata.soapAction)
                                .addCredMetadata(metadata.typeName, jsonToMap(metadata.attributesJson));
            }
            when 'deleteMetadata' {
                result = new MdtWsdl(metadata.soapAction)
                                .setItemMetadataType(metadata.typeName)
                                .addItemMetadataFullName(metadata.fullName);
            }
            when else {
                throw new ApplicationException('Unsupported SOAP action: ' + metadata.soapAction);
            }
        }
    
        return result;
    }
    

    private static Map<String, Object> jsonToMap(String jsonString) {
        return (Map<String, Object>) JSON.deserializeUntyped(jsonString);
    }

    // INNER

    global class MetadataDescription {
        @InvocableVariable(label='SOAP Action' description='One of the allowed SOAP Action types: describeMetadata,listMetadata,readMetadata,createMetadata,updateMetadata,upsertMetadata,deleteMetadata' required=true)
        global String soapAction;

        @InvocableVariable(label='Metadata Type Name' description='The official Salesforce Metadata Type Name' required=false)
        global String typeName;
        
        @InvocableVariable(label='Attributes JSON' description='A JSON with all relevant attributes needed to create this metadata type.' required=false)
        global String attributesJson;
        
        @InvocableVariable(label='Metadata Full Name' description='Some Actions need a Full Name of the existing Metadata record' required=false)
        global String fullName;
    }


    global class Output {
        @InvocableVariable(label='Response Body' description='Raw HTTP Response to be interpreted for Errors or Success')
        global String responseBody;
        
        public Output(String body) {
            responseBody = body;
        }
    }
}