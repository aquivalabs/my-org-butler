@IsTest
private class HeadlessAgent_Test {


    @IsTest
    private static void returnsSuccessfulResponse() {

        // Exercise
        HeadlessAgent agent = new HeadlessAgent('MyOrgButler');
        HeadlessAgent.Response response = agent.send('What accounts do I have?');


        // Verify
        Assert.isTrue(response.success);
        Assert.isNotNull(response.text);
        Assert.isNotNull(response.sessionId);
    }


    @IsTest
    private static void acceptsContextVariables() {

        // Setup
        Map<String, String> context = new Map<String, String>{
            'CaseId' => 'some-case',
            'AccountId' => 'some-account'
        };

        // Exercise
        HeadlessAgent agent = new HeadlessAgent('MyOrgButler');
        HeadlessAgent.Response response = agent.send('Summarize this case', context);


        // Verify
        Assert.isTrue(response.success);
        Assert.isNotNull(response.text);
    }


    @IsTest
    private static void maintainsSessionAcrossTurns() {

        // Exercise
        HeadlessAgent agent = new HeadlessAgent('MyOrgButler');
        HeadlessAgent.Response first = agent.send('Hello');
        HeadlessAgent.Response second = agent.send('Follow up');


        // Verify
        Assert.areEqual(first.sessionId, second.sessionId);
    }
}
