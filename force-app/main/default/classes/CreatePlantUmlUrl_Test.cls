@IsTest
private class CreatePlantUmlUrl_Test {
  
    @IsTest
    private static void execute() {
        // Setup
        CreatePlantUmlUrl.Input input = new CreatePlantUmlUrl.Input();
        input.plantUmlText = '@startuml\nAlice->Bob : I am using hex\n@enduml';

        // Exercise
        List<CreatePlantUmlUrl.Output> results = 
            CreatePlantUmlUrl.execute(new List<CreatePlantUmlUrl.Input>{ input });

        // Verify
        System.assertEquals(1, results.size());
        
        String expectedUrl = 'http://www.plantuml.com/plantuml/png/~h407374617274756d6c0a416c6963652d3e426f62203a204920616d207573696e67206865780a40656e64756d6c';
        System.assertEquals(expectedUrl, results[0].encodedImageUrl);
    }
}