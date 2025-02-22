public with sharing class RenderPlantumlTool extends MyOrgButler.Tool {
    
    public override String execute(String paramsJson) {
        JsonParse parser = new JsonParse(paramsJson);

        RenderPlantuml.Input input = new RenderPlantuml.Input();
        input.plantUmlText = parser.get('plantUmlText').getStringValue();

        List<RenderPlantuml.Output> result = RenderPlantuml.execute(new List<RenderPlantuml.Input>{ input });
        return result[0].encodedImageUrl;
    }
}