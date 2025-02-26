public with sharing class CallMetadataApiTool extends MyOrgButler.Tool {
    
    public override String execute(String paramsJson) {
        JsonParse parser = new JsonParse(paramsJson);

        CallMetadataApi.MetadataDescription metadata = new CallMetadataApi.MetadataDescription();
        metadata.soapAction = parser.get('soapAction').getStringValue();
        metadata.typeName = parser.get('typeName').getStringValue();
        
        if(parser.exists('attributesJson', true)) {
            metadata.attributesJson = parser.get('attributesJson').getStringValue();
        }
        
        List<CallMetadataApi.Output> output = CallMetadataApi.execute(new List<CallMetadataApi.MetadataDescription>{ metadata });
        return JSON.serialize(output[0]);
    }
}