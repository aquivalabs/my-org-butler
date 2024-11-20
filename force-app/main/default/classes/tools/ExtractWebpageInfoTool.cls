public with sharing class ExtractWebpageInfoTool extends MyOrgButler.Tool {

    public override String execute(String jsonParameter) {
        JsonParse parser = new JsonParse(jsonParameter);

        Input input = new Input();
        input.url = parser.get('url').getStringValue();
        input.targetInfo = parser.get('targetInfo').getStringValue();

        List<Output> result = execute(new List<Input>{ input });
        return JSON.serialize(result[0]);
    }

    @InvocableMethod
    public static List<Output> execute(List<Input> inputList) {
        Input input = inputList[0];

        String apiKey = MyOrgButler__c.getInstance().ExtractorApiKey__c;
        if (String.isBlank(apiKey)) {
            throw new ApplicationException('Extractor API Key is not configured.');
        }

        String endpoint = 'https://extractorapi.com/api/v1/extractor/?apikey=' +
            EncodingUtil.urlEncode(apiKey, 'UTF-8') +
            '&url=' +
            EncodingUtil.urlEncode(input.url, 'UTF-8') +
            '&fields=' +
            EncodingUtil.urlEncode('text,raw_text,clean_html', 'UTF-8');

        HttpRequest request = new HttpRequest();
        request.setEndpoint(endpoint);
        request.setMethod('GET');
        request.setTimeout(120000); // Set timeout to 2 minutes

        try {
            HttpResponse response = new Http().send(request);

            ExtractResult result = (ExtractResult) JSON.deserialize(response.getBody(), ExtractResult.class);

            if (result.status_code != 200) {
                throw new ApplicationException(
                    'Failed to extract text from the URL. Status code: ' +
                    result.status_code +
                    ', Status: ' +
                    result.status
                );
            }

            Output output = new Output();
            output.result = getWebText(result);

            return new List<Output>{ output };

        } catch (Exception e) {
            throw new ApplicationException('Failed to fetch data from the provided URL. ' + e.getMessage());
        }
    }

    private static String getWebText(ExtractResult result) {
        List<String> possibleTexts = new List<String>{ result.clean_html, result.raw_text, result.text };
        for (String text : possibleTexts) {
            if (text != null) {
                if (text.length() <= 4000) {
                    return text;
                } else {
                    return text.substring(0, 4000);
                }
            }
        }
        return '';
    }


    // INNER
    public class Input {
        @InvocableVariable(required=true)
        public String url;

        @InvocableVariable
        public String targetInfo;
    }

    public class Output {
        @InvocableVariable
        public String result;
    }

    private class ExtractResult {
        public Integer status_code;
        public String status;
        public String text;
        public String url;
        public String raw_text;
        public String clean_html;
    }
}