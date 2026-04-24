// Note: Agentforce requires Global
@SuppressWarnings('PMD.AvoidGlobalModifier')
global with sharing class SearchDataLibrary {

    @TestVisible
    private static DataLibrary libraryOverride;

    @TestVisible
    private static final Integer MAX_DOCUMENT_LENGTH = 250000;

    @InvocableMethod(label='MyOrgButler: Search Data Library' description='Search company documents in a Data Cloud data library and return answers grounded in the source files.')
    global static List<Output> execute(List<Input> inputs) {
        Output result = new Output();

        result = answerFrom(inputs[0]);

        return new List<Output>{ result };
    }


    // PRIVATE
    
    private static Output answerFrom(Input input) {
        DataLibrary library = libraryOverride != null ? libraryOverride : new DataLibrary();
        DataLibrary.Result data = library.retrieve(input.question, input.chunkDmo, false);

        // Note: If the full document is too long, we use the chunks only approach.
        if(data.documents.length() > MAX_DOCUMENT_LENGTH) {
            data = library.retrieve(input.question, input.chunkDmo, true);
        }

        Output result = new Output();
        result.citations = data.citations;
        result.answer = new PromptTemplate('AnswerFromDocuments')
                                    .call(new Map<String, Object>{
                                        'Input:userQuestion' => input.question,
                                        'Input:documents' => data.documents
                                    })
                                    .text;
        return result;
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
