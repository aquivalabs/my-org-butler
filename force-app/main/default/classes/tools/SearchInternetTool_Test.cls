@IsTest
private class SearchInternetTool_Test {
    
    @IsTest
    private static void execute() {

        // Setup
        String mockResponse = '{' +
            '"answer_box": {' +
                '"answer": "42",' +
                '"snippet": "The answer to life"' +
            '},' +
            '"organic_results": [' +
                '{' +
                    '"snippet": "Result 1",' +
                    '"link": "http://example.com/1"' +
                '},' +
                '{' +
                    '"snippet": "Result 2",' +
                    '"link": "http://example.com/2"' +
                '}' +
            ']' +
        '}';
        new HttpMock().get('/search.json', mockResponse).mock();

        // Exercise
        String response = new SearchInternetTool().execute(new Parameter().asJson());

        // Verify
        System.assertNotEquals(null, response);
        Output output = (Output) JSON.deserialize(response, Output.class);
        System.assertEquals('42', output.answer.answer);
        System.assertEquals('Result 1', output.organicResults[0].snippet);
    }
    
    @IsTest
    private static void exposesExceptions() {

        // Setup
        Exception expectedException = null;

        new HttpMock().get('/search.json', new ApplicationException('Mocked exception')).mock();

        // Exercise
        try {
            new SearchInternetTool().execute(new Parameter().asJson());
        }
        catch(ApplicationException ex) {
            expectedException = ex;
        }

        // Verify
        System.assertNotEquals(null, expectedException);
        System.assertEquals('API returned status code 500', expectedException.getMessage());
    }

    // HELPER

    private class Parameter {
        String query = 'What is the meaning of life?';

        String asJson() {
            return JSON.serialize(this);
        }
    }

    private class Output {
        public AnswerBox answer;
        public Result[] organicResults;
    }

    private class AnswerBox {
        public String answer;
        public String snippet;
    }

    private class Result {
        public String snippet;
        public String link;
    }
}
