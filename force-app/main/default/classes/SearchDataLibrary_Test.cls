@IsTest
private class SearchDataLibrary_Test {

    @IsTest
    private static void execute() {

        // Setup
        DataLibrary.mockedResult = '[]';

        // Exercise
        List<SearchDataLibrary.Output> results = SearchDataLibrary.execute(
            new List<SearchDataLibrary.Input>{ inputWith('What is our refund policy?') }
        );

        // Verify
        Assert.areEqual(1, results.size());
        Assert.areEqual(PromptTemplate.mockedResult, results[0].answer);
    }


    @IsTest
    private static void fallsBackToChunksWhenFullDocumentIsTooLong() {

        // Setup
        DataLibrarySpy spy = new DataLibrarySpy();
        spy.oversizedOnFullRetrieval = true;
        SearchDataLibrary.libraryOverride = spy;


        // Exercise
        SearchDataLibrary.execute(
            new List<SearchDataLibrary.Input>{ inputWith('What is our refund policy?') }
        );


        // Verify
        Assert.areEqual(true, spy.chunksOnlySeen);
    }


    @IsTest
    private static void rethrowsPromptTemplateErrors() {

        // Setup
        SearchDataLibrary.libraryOverride = new DataLibrarySpy();
        PromptTemplate.mockedErrorMessage = 'Einstein had a glitch';


        // Exercise
        Exception caught;
        try {
            SearchDataLibrary.execute(
                new List<SearchDataLibrary.Input>{ inputWith('What is our refund policy?') }
            );
        }
        catch (PromptTemplate.PromptTemplateException error) {
            caught = error;
        }


        // Verify
        Assert.areNotEqual(null, caught);
    }


    // HELPER

    private static SearchDataLibrary.Input inputWith(String question) {
        SearchDataLibrary.Input result = new SearchDataLibrary.Input();
        result.question = question;
        result.chunkDmo = 'TestChunk_chunk__dlm';

        return result;
    }


    // INNER

    private class DataLibrarySpy extends DataLibrary {
        public Boolean chunksOnlySeen = false;
        public Boolean oversizedOnFullRetrieval = false;

        public override DataLibrary.Result retrieve(String query, String chunkDmo, Boolean chunksOnly) {
            if (chunksOnly) {
                chunksOnlySeen = true;
            }

            DataLibrary.Result result = new DataLibrary.Result();
            if (!chunksOnly && oversizedOnFullRetrieval) {
                result.documents = 'x'.repeat(SearchDataLibrary.MAX_DOCUMENT_LENGTH +1);
            }
            return result;
        }
    }
}
