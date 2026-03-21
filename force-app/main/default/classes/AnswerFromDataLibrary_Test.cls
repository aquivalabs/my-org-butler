@IsTest
private class AnswerFromDataLibrary_Test {

    @IsTest
    private static void returnsAnswerFromPromptTemplate() {

        // Setup
        CustomSettings.mock('DataLibraryRetriever', 'test-retriever');

        // Exercise
        List<AnswerFromDataLibrary.Output> results = AnswerFromDataLibrary.execute(
            new List<AnswerFromDataLibrary.Input>{ inputWith('What is our refund policy?') }
        );

        // Verify
        Assert.areEqual(1, results.size());
        Assert.areEqual(PromptTemplate.mockedResult, results[0].answer);
    }


    // HELPER

    private static AnswerFromDataLibrary.Input inputWith(String question) {
        AnswerFromDataLibrary.Input result = new AnswerFromDataLibrary.Input();
        result.question = question;

        return result;
    }
}
