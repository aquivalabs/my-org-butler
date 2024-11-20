public with sharing class ExtractWebpageInfoTool extends MyOrgButler.Tool {

    public override String execute(String jsonParameter) {
        JsonParse parser = new JsonParse(jsonParameter);

        Input input = new Input();
        input.url = parser.get('url').getStringValue();
        input.targetInfo = parser.has('targetInfo') ? parser.get('targetInfo').getStringValue() : null;

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

        HttpRequest req = new HttpRequest();
        req.setEndpoint(endpoint);
        req.setMethod('GET');
        req.setTimeout(120000); // Set timeout to 2 minutes

        try {
            HttpResponse res = new Http().send(req);

            ExtractResult result = (ExtractResult) JSON.deserialize(res.getBody(), ExtractResult.class);

            if (result.status_code != 200) {
                throw new ApplicationException(
                    'Failed to extract text from the URL. Status code: ' +
                    result.status_code +
                    ', Status: ' +
                    result.status
                );
            }

            String webText;
            if (result.clean_html != null && result.clean_html.length() < 4000) {
                webText = result.clean_html;
            } else if (result.raw_text != null && result.raw_text.length() < 4000) {
                webText = result.raw_text;
            } else if (result.text != null && result.text.length() < 4000) {
                webText = result.text;
            } else {
                webText = result.text != null ? result.text.substring(0, 4000) : '';
            }

            Output output = new Output();

            if (!String.isBlank(input.targetInfo)) {
                String summary = summarizeText(input.targetInfo, webText);
                output.result = summary;
            } else {
                output.result = webText;
            }

            return new List<Output>{ output };

        } catch (Exception e) {
            throw new ApplicationException('Failed to fetch data from the provided URL. ' + e.getMessage());
        }
    }

    private static String summarizeText(String targetInfo, String webText) {
        // Implement summarization logic here
        return 'Summary based on target info: ' + targetInfo + '\n\n' + webText.substring(0, Math.min(500, webText.length()));
    }

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