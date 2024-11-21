@IsTest
private class SearchWebTool_Test {
    
    @IsTest
    private static void happyPath() {

        // Setup
        insert new MyOrgButler__c(TavilyApiKey__c = '123');

        SearchWebTool.Answer expected = answerWith('Donald Trump was elected in November 2024.');
        new HttpMock()
                .post('/search', expected)
                .mock();

        // Exercise
        Test.startTest();
        String response = new SearchWebTool().execute('{ "query" : "Who is the 47th US president?" }');
        Test.stopTest();

        // Verify
        SearchWebTool.Answer actual = (SearchWebTool.Answer) JSON.deserialize(response, SearchWebTool.Answer.class);
        System.assertEquals(expected.answer, actual.answer);
    }

    // HELPER

    private static SearchWebTool.Answer answerWith(String content) {
        SearchWebTool.Answer result = new SearchWebTool.Answer();
        result.answer = content;
        return result;
    }
}
