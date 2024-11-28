public with sharing class UseMetadataApiTool extends MyOrgButler.Tool {
    
    public override String execute(String paramsJson) {
        JsonParse parser = new JsonParse(paramsJson);

        UseMetadataApi.MetadataDescription metadata = new UseMetadataApi.MetadataDescription();
        metadata.typeName = parser.get('typeName').getStringValue();
        metadata.attributesJson = parser.get('attributesJson').getStringValue();
        
        List<UseMetadataApi.Output> output = UseMetadataApi.execute(new List<UseMetadataApi.MetadataDescription>{ metadata });
        return JSON.serialize(output[0]);
    }
}