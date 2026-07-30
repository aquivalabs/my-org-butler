@IsTest
private class SearchWeb_Test {
    
    @IsTest
    private static void happyPath() {

        // Setup
        new HttpMock()
                .post('/search').body(new Map<String, Object>{
                    'answer' => 'Donald Trump was elected in November 2024.',
                    'results' => new List<Object>{
                        new Map<String, Object>{ 'url' => 'https://apnews.com/election' }
                    }
                }).statusCodeOk()
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
        Assert.areEqual('Donald Trump was elected in November 2024.', actual.answer);
        Assert.areEqual(new List<String>{ 'https://apnews.com/election' }, actual.urls);
    }
}
