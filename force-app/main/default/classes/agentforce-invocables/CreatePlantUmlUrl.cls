// PMD False Positives:
public with sharing class CreatePlantUmlUrl {
    private static final String PLANTUML_URL_PREFIX = 'http://www.plantuml.com/plantuml/png/~h';
    
    @InvocableMethod(label='MyOrgButler: Render PlantUML Diagram' description='Converts PlantUML text notation into a rendered diagram image URL')
    public static List<Output> execute(List<Input> inputs) {
        Output output = new Output();
        
        Blob textBlob = Blob.valueOf(inputs[0].plantUmlText);
        output.encodedImageUrl = PLANTUML_URL_PREFIX + EncodingUtil.convertToHex(textBlob).toLowerCase();
        
        return new List<Output>{ output };
    }

    // INNER

    public class Input {
        @InvocableVariable(label='PlantUML Text' description='The PlantUML diagram definition in text format (e.g., @startuml\\nAlice->Bob : hello\\n@enduml)' required=true)
        public String plantUmlText;
    }

    public class Output {
        @InvocableVariable(label='Diagram Image URL' description='URL to the rendered PlantUML diagram image' required=true)
        public String encodedImageUrl;
    }
}