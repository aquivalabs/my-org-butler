@IsTest
private class SearchWeb_Test {
    
    @IsTest
    private static void happyPath() {

        // Setup
        SearchWeb.Answer expected = answerWith('Donald Trump was elected in November 2024.');
        new HttpMock()
                .post('/search').body(expected).statusCodeOk()
                .mock();

        SearchWeb.Query query = new SearchWeb.Query();
        query.content = 'Who is the 47th US president?';

        // Exercise
        Test.startTest();
        List<SearchWeb.Answer> response = SearchWeb.execute(new List<SearchWeb.Query>{ query });
        Test.stopTest();

        // Verify
        Assert.areEqual(1, response.size());
        SearchWeb.Answer actual = response[0];
        Assert.areEqual(expected.answer, actual.answer);
    }

    // HELPER

    private static SearchWeb.Answer answerWith(String content) {
        SearchWeb.Answer result = new SearchWeb.Answer();
        result.answer = content;
        return result;
    }
}
