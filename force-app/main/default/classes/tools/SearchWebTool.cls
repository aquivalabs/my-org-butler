@SuppressWarnings('PMD.ApexSuggestUsingNamedCred')
public with sharing class SearchWebTool extends MyOrgButler.Tool {

    public override String execute(String jsonParameter) {
        JsonParse parser = new JsonParse(jsonParameter);

        Query query = new Query();
        query.content = parser.get('query').getStringValue();

        List<Answer> result = execute(new List<Query>{ query });
        return JSON.serialize(result[0]);
    }

    @InvocableMethod
    public static List<Answer> execute(List<Query> queries) {
        HttpRequest request = new HttpRequest();
        request.setEndpoint('https://api.tavily.com/search');
        request.setMethod('POST');
        request.setHeader('Content-Type', 'application/json');

        Map<String, Object> body = new Map<String, Object>{ 
            'query' => queries[0].content,
            'api_key' => tavilyApiKey(),
            'include_answer' => true
        };
        request.setBody( JSON.serialize(body) );

        HttpResponse response = new Http().send(request);
        if(response.getStatusCode() >= 300) {
            throw new ApplicationException('Failed to perform web search. HTTP Request failed with code: ' + response.getStatusCode() + ' and message: ' + response.getBody() + '.');
        }

        Answer answer = (Answer) JSON.deserialize(response.getBody(), Answer.class);
        return new List<Answer>{ answer };

    }

    // PRIVATE

    private static String tavilyApiKey() {
        String result = MyOrgButler__c.getOrgDefaults().TavilyApiKey__c;

        if (String.isBlank(result)) {
            throw new ApplicationException('Tavily API Key is not configured.');
        }
        return result;
    }

    // INNER

    public class Query {
        @InvocableVariable(required=true)
        public String content;
    }

    public class Answer {
        @InvocableVariable(required=true)
        public String answer;
    }
}
