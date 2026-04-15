// Note: Agentforce requires Global
@SuppressWarnings('PMD.AvoidGlobalModifier')
global with sharing class SearchDataLibrary {

    @InvocableMethod(label='MyOrgButler: Search Data Library' description='Search company documents in a Data Cloud data library and return answers grounded in the source files.')
    global static List<Output> execute(List<Input> inputs) {
        Input input = inputs[0];

        String documents = new DataLibrary().retrieve(input.question, input.chunkDmo, input.searchIndex, false);

        PromptTemplate.Result result = new PromptTemplate('AnswerFromDocuments')
                            .call(new Map<String, Object>{
                                'Input:userQuestion' => input.question,
                                'Input:documents' => documents
                            });

        Output output = new Output();
        output.answer = result.text;

        return new List<Output>{ output };
    }


    // INNER

    global class Input {
        @InvocableVariable(label='Question' description='The question to answer using the company knowledge base.' required=true)
        global String question;

        @InvocableVariable(label='Chunk DMO' description='API name of the Data Cloud chunk entity (ending in _chunk__dlm). Use ExploreDataCloud to find it.' required=true)
        global String chunkDmo;

        @InvocableVariable(label='Search Index' description='API name of the Data Cloud search index entity (ending in _index__dlm). Use ExploreDataCloud to find it.' required=true)
        global String searchIndex;
    }


    global class Output {
        @InvocableVariable(label='Answer' description='AI-generated answer grounded in company documents with inline source citations.')
        global String answer;
    }
}
