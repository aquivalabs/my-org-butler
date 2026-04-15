@IsTest
private class PromptTemplate_Test {

    @IsTest
    private static void callReturnsGeneratedText() {

        // Exercise
        PromptTemplate.Result result = new PromptTemplate('TestTemplate')
            .call(new Map<String, Object>{
                'Input:query' => 'test question'
            });

        // Verify
        Assert.areEqual(PromptTemplate.mockedResult, result.text);
    }


    @IsTest
    private static void callWithMultipleParams() {

        // Exercise
        PromptTemplate.Result result = new PromptTemplate('TestTemplate')
            .call(new Map<String, Object>{
                'Input:param1' => 'value1',
                'Input:param2' => 'value2'
            });

        // Verify
        Assert.areEqual(PromptTemplate.mockedResult, result.text);
    }
}
