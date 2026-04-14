// PMD False Positives: Agentforce requires Global
@SuppressWarnings('PMD.AvoidGlobalModifier')
global with sharing class AnswerFromDataLibrary {

    @InvocableMethod(label='MyOrgButler: Answer from Data Library' description='Answer questions using company documents stored in a Data Cloud data library.')
    global static List<Output> execute(List<Input> inputs) {
        Input input = inputs[0];

        PromptTemplate.Result result = new PromptTemplate('AnswerFromDataLibrary')
                            .call(new Map<String, Object>{
                                'Input:userQuestion' => input.question,
                                'Input:RetrieverId' => CustomSettings.valueFor('DataLibraryRetriever'),
                                'Input:documentContext' => new SemanticSearch().execute(input.question, CustomSettings.optionalValueFor('DataLibraryChunkDmo'))
                            });

        Output output = new Output();
        output.answer = result.text;
        output.citations = result.citations;

        return new List<Output>{ output };
    }


    // INNER

    global class Input {
        @InvocableVariable(label='Question' description='The question to answer using the company knowledge base.' required=true)
        global String question;
    }


    global class Output {
        @InvocableVariable(label='Answer' description='AI-generated answer grounded in company documents.')
        global String answer;

        @InvocableVariable(label='Citations' description='Source references for the generated answer.')
        global AiCopilot.GenAiCitationInput citations;
    }
}
