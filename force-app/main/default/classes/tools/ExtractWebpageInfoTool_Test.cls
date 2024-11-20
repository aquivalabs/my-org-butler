@IsTest
private class ExtractWebpageInfoTool_Test {

    @IsTest
    private static void executeWithTargetInfo() {
        String mockResponse = '{' +
            '"status_code": 200,' +
            '"status": "OK",' +
            '"text": "This is the extracted text from the webpage.",' +
            '"raw_text": "This is the raw text from the webpage.",' +
            '"clean_html": "<p>This is the clean HTML content of the webpage.</p>"' +
        '}';

        new HttpMock().get('/api/v1/extractor/', mockResponse).mock();

        Parameter param = new Parameter();
        param.url = 'http://example.com';
        param.targetInfo = 'Summarize the main points';

        String response = new ExtractWebpageInfoTool().execute(param.asJson());

        System.assertNotEquals(null, response);
        Output output = (Output) JSON.deserialize(response, Output.class);
        System.assertNotEquals(null, output.result);
        System.assert(output.result.contains('Summary based on target info'), 'Summary should contain the target info');
    }

    @IsTest
    private static void executeWithoutTargetInfo() {
        String mockResponse = '{' +
            '"status_code": 200,' +
            '"status": "OK",' +
            '"text": "This is the extracted text from the webpage.",' +
            '"raw_text": "This is the raw text from the webpage.",' +
            '"clean_html": "<p>This is the clean HTML content of the webpage.</p>"' +
        '}';

        new HttpMock().get('/api/v1/extractor/', mockResponse).mock();

        Parameter param = new Parameter();
        param.url = 'http://example.com';

        String response = new ExtractWebpageInfoTool().execute(param.asJson());

        System.assertNotEquals(null, response);
        Output output = (Output) JSON.deserialize(response, Output.class);
        System.assertEquals('<p>This is the clean HTML content of the webpage.</p>', output.result);
    }

    @IsTest
    private static void exposesExceptions() {
        Exception expectedException = null;

        new HttpMock().get('/api/v1/extractor/', new ApplicationException('Mocked exception')).mock();

        Parameter param = new Parameter();
        param.url = 'http://example.com';

        try {
            new ExtractWebpageInfoTool().execute(param.asJson());
        } catch(ApplicationException ex) {
            expectedException = ex;
        }

        System.assertNotEquals(null, expectedException);
    }

    private class Parameter {
        String url;
        String targetInfo;

        String asJson() {
            return JSON.serialize(this);
        }
    }

    private class Output {
        public String result;
    }
}