// PMD False Positives: Agentforce requires Global
@SuppressWarnings('PMD.AvoidGlobalMethod,PMD.ApexSuggestUsingNamedCred')
global with sharing class CallGitHubApi {

    @InvocableMethod(label='MyOrgButler: Call GitHub API' description='Call the GitHub API using the GitHub Named Credential')
    global static List<Output> execute(List<Input> requests) {
        Input req = requests[0];
        HttpRequest request = new HttpRequest();
        request.setEndpoint('callout:aquiva_os__GitHubApi' + req.urlIncludingParams);
        request.setMethod(req.httpMethod);
        request.setHeader('Content-Type', 'application/json');
        String body = req.requestBody;
        if (String.isNotEmpty(body)) {
            request.setBody(body);
        }
        HttpResponse response = new Http().send(request);
        return new List<Output>{ new Output(response.getBody()) };
    }

    global class Input {
        @InvocableVariable(label='Endpoint URL' description='The GitHub API endpoint URL to call, starting with / and including any query parameters' required=true)
        global String urlIncludingParams;

        @InvocableVariable(label='HTTP Method' description='The HTTP method to use (GET, POST, PATCH, DELETE)' required=true)
        global String httpMethod;

        @InvocableVariable(label='Request Body' description='JSON payload for POST or PATCH requests' required=false)
        global String requestBody;
    }

    global class Output {
        @InvocableVariable(
            label='Response Body'
            description='Raw HTTP Response to be interpreted for Errors or Success'
            required=true
        )
        global String responseBody;

        public Output(String body) {
            this.responseBody = body;
        }
    }
}