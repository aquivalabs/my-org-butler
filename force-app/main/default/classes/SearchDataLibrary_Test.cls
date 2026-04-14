@IsTest
private class SearchDataLibrary_Test {

    @IsTest
    private static void returnsAnswerFromPromptTemplate() {

        // Setup
        DataLibrary.mockedResult = '[]';

        // Exercise
        List<SearchDataLibrary.Output> results = SearchDataLibrary.execute(
            new List<SearchDataLibrary.Input>{ inputWith('What is our refund policy?', 'TestChunk_chunk__dll') }
        );

        // Verify
        Assert.areEqual(1, results.size());
        Assert.areEqual(PromptTemplate.mockedResult, results[0].answer);
    }


    // HELPER

    private static SearchDataLibrary.Input inputWith(String question, String chunkDmo) {
        SearchDataLibrary.Input result = new SearchDataLibrary.Input();
        result.question = question;
        result.chunkDmo = chunkDmo;

        return result;
    }
}
