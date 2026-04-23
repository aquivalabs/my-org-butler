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
    private static void fallsBackToChunks() {

        // Setup
        DataLibrarySpy spy = new DataLibrarySpy();
        SearchDataLibrary.libraryOverride = spy;
        PromptTemplate.throwOnNextCall = true;


        // Exercise
        SearchDataLibrary.execute(
            new List<SearchDataLibrary.Input>{ inputWith('What is our refund policy?') }
        );


        // Verify
        Assert.areEqual(true, spy.chunksOnlySeen);
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

        public override DataLibrary.Result retrieve(String query, String chunkDmo, Boolean chunksOnly) {
            if (chunksOnly) {
                chunksOnlySeen = true;
            }

            return new DataLibrary.Result();
        }
    }
}
