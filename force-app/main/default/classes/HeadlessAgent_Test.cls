@IsTest
private class HeadlessAgent_Test {


    @IsTest
    private static void returnsSuccessfulResponse() {

        // Exercise
        HeadlessAgent agent = new HeadlessAgent('MyOrgButler');
        HeadlessAgent.Response response = agent.prompt('What accounts do I have?');


        // Verify
        Assert.isTrue(response.success);
        Assert.isNotNull(response.text);
        Assert.isNotNull(response.sessionId);
    }


    @IsTest
    private static void acceptsContextVariables() {

        // Setup
        Map<String, String> context = new Map<String, String>{
            'CaseId' => '500000000000001',
            'AccountId' => '001000000000001'
        };

        // Exercise
        HeadlessAgent agent = new HeadlessAgent('MyOrgButler');
        HeadlessAgent.Response response = agent.prompt('Summarize this case', context);


        // Verify
        Assert.isTrue(response.success);
        Assert.isNotNull(response.text);
    }


    @IsTest
    private static void maintainsSessionAcrossTurns() {

        // Exercise
        HeadlessAgent agent = new HeadlessAgent('MyOrgButler');
        HeadlessAgent.Response first = agent.prompt('Hello');
        HeadlessAgent.Response second = agent.prompt('Follow up');


        // Verify
        Assert.areEqual(first.sessionId, second.sessionId);
    }
}
