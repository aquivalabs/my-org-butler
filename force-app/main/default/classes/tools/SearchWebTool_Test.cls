@IsTest
private class SearchWebTool_Test {
    
    @IsTest
    private static void happyPath() {

        // Setup
        insert new MyOrgButler__c(TavilyApiKey__c = '123');

        SearchWeb.Answer expected = answerWith('Donald Trump was elected in November 2024.');
        new HttpMock()
                .post('/search', expected)
                .mock();

        // Exercise
        Test.startTest();
        String response = new SearchWebTool().execute('{ "query" : "Who is the 47th US president?" }');
        Test.stopTest();

        // Verify
        SearchWeb.Answer actual = (SearchWeb.Answer) JSON.deserialize(response, SearchWeb.Answer.class);
        System.assertEquals(expected.answer, actual.answer);
    }

    // HELPER

    private static SearchWeb.Answer answerWith(String content) {
        SearchWeb.Answer result = new SearchWeb.Answer();
        result.answer = content;
        return result;
    }
}
