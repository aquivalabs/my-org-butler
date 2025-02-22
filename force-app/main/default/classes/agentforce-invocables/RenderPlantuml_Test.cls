@IsTest
private class RenderPlantuml_Test {
  
    @IsTest
    private static void execute() {
        // Setup
        RenderPlantuml.Input input = new RenderPlantuml.Input();
        input.plantUmlText = '@startuml\nAlice->Bob : I am using hex\n@enduml';

        // Exercise
        List<RenderPlantuml.Output> results = 
            RenderPlantuml.execute(new List<RenderPlantuml.Input>{ input });

        // Verify
        System.assertEquals(1, results.size());
        
        String expectedUrl = 'http://www.plantuml.com/plantuml/png/~h407374617274756d6c0a416c6963652d3e426f62203a204920616d207573696e67206865780a40656e64756d6c';
        System.assertEquals(expectedUrl, results[0].encodedImageUrl);
    }
}