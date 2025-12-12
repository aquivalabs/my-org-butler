// PMD False Positives: Agentforce requires Global
@SuppressWarnings('PMD.AvoidGlobalMethod,PMD.ApexSuggestUsingNamedCred')
global with sharing class CallAzureDevOpsApi {

    @InvocableMethod(label='MyOrgButler: Call Azure DevOps API' description='Call the Azure DevOps API using the Azure DevOps Named Credential')
    global static List<Output> execute(List<Input> requests) {
        Input req = requests[0];
        HttpRequest request = new HttpRequest();
        
        // Azure DevOps endpoint structure: callout:NamedCredential + API path
        request.setEndpoint('callout:aquiva_os__AzureDevOpsApi' + req.urlIncludingParams);
        request.setMethod(req.httpMethod);
        
        // Azure DevOps API headers
        request.setHeader('Content-Type', 'application/json');
        request.setHeader('Accept', 'application/json');
        
        // Set request body if provided
        String body = req.requestBody;
        if (String.isNotEmpty(body)) {
            request.setBody(body);
        }
        
        HttpResponse response = new Http().send(request);
        return new List<Output>{ new Output(response.getBody()) };
    }

    global class Input {
        @InvocableVariable(label='Endpoint URL' description='The Azure DevOps API endpoint URL to call, starting with / and including any query parameters (e.g., /_apis/projects?api-version=7.0)' required=true)
        global String urlIncludingParams;

        @InvocableVariable(label='HTTP Method' description='The HTTP method to use (GET, POST, PATCH, DELETE, PUT)' required=true)
        global String httpMethod;

        @InvocableVariable(label='Request Body' description='JSON payload for POST, PATCH, or PUT requests' required=false)
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
