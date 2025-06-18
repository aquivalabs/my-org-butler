// PMD False Positives: Agentforce requires Global
@SuppressWarnings('PMD.AvoidGlobalMethod')
global with sharing class CreatePlantUmlUrl {
    private static final String PLANTUML_URL_PREFIX = 'http://www.plantuml.com/plantuml/png/~h';
    
    @InvocableMethod(label='MyOrgButler: Render PlantUML Diagram' description='Converts PlantUML text notation into a rendered diagram image URL')
    global static List<Output> execute(List<Input> inputs) {
        Output output = new Output();
        
        Blob textBlob = Blob.valueOf(inputs[0].plantUmlText);
        output.encodedImageUrl = PLANTUML_URL_PREFIX + EncodingUtil.convertToHex(textBlob).toLowerCase();
        
        return new List<Output>{ output };
    }

    // INNER

    global class Input {
        @InvocableVariable(label='PlantUML Text' description='The PlantUML diagram definition in text format (e.g., @startuml\\nAlice->Bob : hello\\n@enduml)' required=true)
        global String plantUmlText;
    }

    global class Output {
        @InvocableVariable(label='Diagram Image URL' description='URL to the rendered PlantUML diagram image' required=true)
        global String encodedImageUrl;
    }
}