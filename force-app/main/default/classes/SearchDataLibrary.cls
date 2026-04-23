// Note: Agentforce requires Global
@SuppressWarnings('PMD.AvoidGlobalModifier')
global with sharing class SearchDataLibrary {

    @TestVisible
    private static DataLibrary libraryOverride;

    @InvocableMethod(label='MyOrgButler: Search Data Library' description='Search company documents in a Data Cloud data library and return answers grounded in the source files.')
    global static List<Output> execute(List<Input> inputs) {
        Output result = new Output();

        try {
            result = answerFromFullDocument(inputs[0]);
        }
        catch (PromptTemplate.PromptTemplateException error) {
            if(!isTokenLimit(error)) {
                throw error;
            }

            result = answerFromChunks(inputs[0]);
        }

        return new List<Output>{ result };
    }


    // PRIVATE

    private static Output answerFromFullDocument(Input input) {
        return answerFrom(input, false);
    }


    private static Output answerFromChunks(Input input) {
        return answerFrom(input, true);
    }

    
    private static Output answerFrom(Input input, Boolean chunksOnly) {
        DataLibrary library = libraryOverride != null ? libraryOverride : new DataLibrary();
        DataLibrary.Result data = library.retrieve(input.question, input.chunkDmo, chunksOnly);

        Output result = new Output();
        result.citations = data.citations;
        result.answer = answerFrom(input.question, data.documents);
        return result;
    }

    private static Boolean isTokenLimit(PromptTemplate.PromptTemplateException error) {
        String message = error.getMessage();
        return message != null
            && (message.containsIgnoreCase('exceeds the token limit')
            ||  message.containsIgnoreCase('exceeds model size limit'));
    }


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
