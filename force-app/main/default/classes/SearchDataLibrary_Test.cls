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


    // HELPER

    private static SearchDataLibrary.Input inputWith(String question) {
        SearchDataLibrary.Input result = new SearchDataLibrary.Input();
        result.question = question;
        result.chunkDmo = 'TestChunk_chunk__dlm';

        return result;
    }
}
