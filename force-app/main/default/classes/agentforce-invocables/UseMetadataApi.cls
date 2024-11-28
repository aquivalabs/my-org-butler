// PMD False Positives: 
// - Only global invocables are seen in installed org
@SuppressWarnings('PMD.AvoidGlobalModifier')
global with sharing class UseMetadataApi {
    
    @InvocableMethod(label='MyOrgButler: Create Metadata' description='Creates XML Metadata (no code) in the org. Uses an Apex Wrapper to call the SOAP MDAPI')
    global static List<Output> execute(List<MetadataDescription> descriptions) {
        List<Output> result = new List<Output>();

        for(MetadataDescription metadata : descriptions) {
            try {
                Wsdl action = new MdtWsdl('upsertMetadata')
                                            .addCredMetadata(metadata.typeName, jsonToMap(metadata.attributesJson))
                                            .setDefaultNamespace('soap')
                                            .call()
                                            .handleErrors();

                result.add(new Output(action.getResponse()?.getBody()));
            }
            catch(Wsdl.SoapApiException ex) {
                throw new ApplicationException('Deploy Metadata Action failed: ' + ex.getMessage(), ex);
            }
        }
            
        return result;
    }

    // PRIVATE

    private static Map<String, Object> jsonToMap(String jsonString) {
        return (Map<String, Object>) JSON.deserializeUntyped(jsonString);
    }

    // INNER

    global class MetadataDescription {
        @InvocableVariable(label='Metadata Type Name' description='The official Salesforce Metadata Type Name' required=true)
        global String typeName;
        
        @InvocableVariable(label='Attributes JSON' description='A JSON with all relevant attributes needed to create this metadata type.' required=true)
        global String attributesJson;
    }


    global class Output {
        @InvocableVariable(label='Response Body' description='Raw HTTP Response to be interpreted for Errors or Success')
        global String responseBody;
        
        public Output(String body) {
            responseBody = body;
        }
    }
}