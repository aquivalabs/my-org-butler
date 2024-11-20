public with sharing class SearchInternetTool extends MyOrgButler.Tool {

    public override String execute(String jsonParameter) {
        JsonParse parser = new JsonParse(jsonParameter);

        Input input = new Input();
        input.query = parser.get('query').getStringValue();

        List<Output> result = execute(new List<Input>{ input });
        return JSON.serialize(result[0]);
    }

    @InvocableMethod
    public static List<Output> execute(List<Input> inputList) {
        Input input = inputList[0];

        if (String.isBlank(input.query)) {
            throw new ApplicationException('Query is empty');
        }

        HttpRequest request = new HttpRequest();
        request.setMethod('GET');

        String apiKey = MyOrgButler__c.getInstance().SearchApiKey__c;
        if (String.isBlank(apiKey)) {
            throw new ApplicationException('Search API Key is not configured.');
        }

        String endpoint = 'https://serpapi.com/search.json?q=' +
            EncodingUtil.urlEncode(input.query, 'UTF-8') +
            '&hl=en&gl=us&api_key=' +
            EncodingUtil.urlEncode(apiKey, 'UTF-8');

        request.setEndpoint(endpoint);

        try {
            HttpResponse response = new Http().send(request);

            if (response.getStatusCode() == 200) {
                // Deserialize the response
                TypedResult data = (TypedResult) JSON.deserialize(
                    response.getBody().replace('"list":', '"items":'),
                    TypedResult.class
                );

                Output output = new Output();
                output.answer = data.answer_box;
                if (data.organic_results != null && data.organic_results.size() > 0) {
                    output.organicResults = data.organic_results;
                }

                return new List<Output>{ output };
            } else {
                throw new ApplicationException(
                    'API returned status code ' + response.getStatusCode()
                );
            }
        } catch (Exception e) {
            throw new ApplicationException('HTTP callout failed: ' + e.getMessage());
        }
    }

    // INNER

    public class Input {
        @InvocableVariable(required=true)
        public String query;
    }

    public class Output {
        @InvocableVariable
        public AnswerBox answer;
        @InvocableVariable
        public Result[] organicResults;
    }

    // Data models for deserialization

    private class TypedResult {
        public AnswerBox answer_box;
        public Result[] organic_results;
        public GraphResult knowledge_graph;
    }

    public class AnswerBox {
        public String answer;
        public String[] items;
        public String snippet;
    }

    public class Result {
        public String snippet;
        public String[] snippet_highlighted_words;
        public String link;
    }

    public class GraphResult {
        public String description;
    }
}