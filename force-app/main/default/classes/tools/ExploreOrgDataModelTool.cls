public with sharing class ExploreOrgDataModelTool extends MyOrgButler.Tool {
    
    public override String execute(String paramsJson) {
        JsonParse parser = new JsonParse(paramsJson);

        ExploreOrgDataModel.Input request = new ExploreOrgDataModel.Input();
        request.scope = parser.get('scope').getStringValue();
        
        if(parser.exists('objects', true)) {
            request.objects = parser.get('objects').getStringValue();
        }

        List<ExploreOrgDataModel.Output> result = ExploreOrgDataModel.investigateSchema(new List<ExploreOrgDataModel.Input>{ request });
        return result[0].response;
    }
}