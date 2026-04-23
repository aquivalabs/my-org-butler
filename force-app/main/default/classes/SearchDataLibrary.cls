// Note: Agentforce requires Global
@SuppressWarnings('PMD.AvoidGlobalModifier')
global with sharing class SearchDataLibrary {

    @InvocableMethod(label='MyOrgButler: Search Data Library' description='Search company documents in a Data Cloud data library and return answers grounded in the source files.')
    global static List<Output> execute(List<Input> inputs) {
        Input input = inputs[0];
        DataLibrary library = new DataLibrary();

        DataLibrary.Result data = library.retrieve(input.question, input.chunkDmo, false);
        String answer;

        try {
            answer = answerFrom(input.question, data.documents);
        }
        catch (Exception error) {
            // Note: Full-document payload can blow past prompt-template limits on large files;
            // fall back to top matching chunks only.
            data = library.retrieve(input.question, input.chunkDmo, true);
            answer = answerFrom(input.question, data.documents);
        }

        Output output = new Output();
        output.answer = answer;
        output.citations = data.citations;

        return new List<Output>{ output };
    }


    // PRIVATE

    private static String answerFrom(String question, String documents) {
        return new PromptTemplate('AnswerFromDocuments')
            .call(new Map<String, Object>{
                'Input:userQuestion' => question,
                'Input:documents' => documents
            })
            .text;
    }


    // INNER

    global class Input {
        @InvocableVariable(label='Question' description='The question to answer using the company knowledge base.' required=true)
        global String question;

        @InvocableVariable(label='Chunk DMO' description='API name of the Data Cloud chunk entity (ending in _chunk__dlm). Use ExploreDataCloud to find it.' required=true)
        global String chunkDmo;
    }


    global class Output {
        @InvocableVariable(label='Answer' description='AI-generated answer grounded in company documents with inline source citations.')
        global String answer;

        @InvocableVariable(label='Citations' description='Source references for the generated answer.')
        global AiCopilot.GenAiCitationInput citations;
    }
}
