// PMD False Positives: Agentforce requires Global
@SuppressWarnings('PMD.AvoidGlobalModifier')
global with sharing class SearchWeb {

    @InvocableMethod(label='MyOrgButler: Search Web' description='Performs a web search using the Tavily API and returns the answer.')
    global static List<Answer> execute(List<Query> queries) {
        HttpRequest request = new HttpRequest();
        request.setEndpoint('callout:aquiva_os__TavilyApi/search');
        request.setMethod('POST');
        request.setHeader('Content-Type', 'application/json');

        Map<String, Object> body = new Map<String, Object>{ 
            'query' => queries[0].content,
            'api_key' => '{!$Credential.TavilyApi.ApiKey}',
            'include_answer' => true
        };
        request.setBody( JSON.serialize(body) );

        HttpResponse response = new Http().send(request);
        Map<String, Object> payload = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());

        Answer answer = new Answer();
        answer.answer = (String) payload.get('answer');

        // Note: a Tavily error body has no results, so the agent is left with no URL it may cite.
        for(Object hit : (List<Object>) (payload.get('results') ?? new List<Object>())) {
            answer.urls.add( (String) ((Map<String, Object>) hit).get('url') );
        }

        return new List<Answer>{ answer };
    }

    // INNER

    global class Query {
        @InvocableVariable(label='Query' description='A natural language search query to search the web for and get an answer for.')
        global String content;
    }

    global class Answer {
        @InvocableVariable(label='Answer' description='The Natural Language Answer for the Query generated after doing a Web Search.')
        global String answer;

        @InvocableVariable(label='URLs' description='The web pages the answer is based on. These are the ONLY URLs that may be cited. If empty, cite nothing and do not construct a URL.')
        global List<String> urls = new List<String>();
    }
}