public with sharing class ExploreOrgSchemaTool extends MyOrgButler.Tool {
    
    public override String execute(String paramsJson) {
        JsonParse parser = new JsonParse(paramsJson);

        ExploreOrgSchema.Input request = new ExploreOrgSchema.Input();
        request.scope = parser.get('scope').getStringValue();
        
        if(parser.exists('objects', true)) {
            request.objects = parser.get('objects').getStringValue();
        }

        List<ExploreOrgSchema.Output> result = ExploreOrgSchema.investigateSchema(new List<ExploreOrgSchema.Input>{ request });
        return result[0].response;
    }
}