@IsTest
private class CallGitHubApi_Test {
    
    @IsTest
    private static void execute() {
        // Setup
        new HttpMock()
                .get('/repos/owner/repo').body('{ "name": "repo", "full_name": "owner/repo" }').statusCodeOk()
                .mock();

        CallGitHubApi.Input input = new CallGitHubApi.Input();
        input.urlIncludingParams = '/repos/owner/repo';
        input.httpMethod = 'GET';
        input.requestBody = null;

        // Exercise
        List<CallGitHubApi.Output> response = CallGitHubApi.execute(new List<CallGitHubApi.Input>{ input });

        // Verify
        System.assertEquals('{ "name": "repo", "full_name": "owner/repo" }', response[0].responseBody);
    }
}
