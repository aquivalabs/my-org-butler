public with sharing class CreatePlantUmlUrlTool extends MyOrgButler.Tool {
    
    public override String execute(String paramsJson) {
        JsonParse parser = new JsonParse(paramsJson);

        CreatePlantUmlUrl.Input input = new CreatePlantUmlUrl.Input();
        input.plantUmlText = parser.get('plantUmlText').getStringValue();

        List<CreatePlantUmlUrl.Output> result = CreatePlantUmlUrl.execute(new List<CreatePlantUmlUrl.Input>{ input });
        return result[0].encodedImageUrl;
    }
}