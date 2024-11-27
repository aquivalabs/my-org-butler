
// PMD False Positives: 
// - Only global invocables are seen in installed org
// - Calling regular Salesforce APIs can be done with Session Id
@SuppressWarnings('PMD.AvoidGlobalModifier, PMD.ApexSuggestUsingNamedCred')
global with sharing class CallSalesforceApi {

    @InvocableMethod(label='MyOrgButler: Call Salesforce API' description='Call an official public Salesforce API REST endpoint')
    global static List<Output> execute(List<Input> input) {
        HttpRequest request = new HttpRequest();  
        request.setHeader('Authorization', 'Bearer ' + new SessionId().asString()); 
        request.setHeader('Content-Type', 'application/json');
        request.setEndpoint(Url.getOrgDomainURL().toExternalForm() + input[0].urlIncludingParams);
        request.setMethod(input[0].httpMethod);   

        String body = input[0].requestBody;
        if(String.isNotEmpty(body)) {
            request.setBody(body);
        }

        HttpResponse response = new Http().send(request);
        if(response.getStatusCode() >= 300) {
            throw new ApplicationException('HTTP Request failed with code: ' + response.getStatusCode() + ' and message: ' + response.getBody() + '.');
        }

        return new List<Output>{ new Output(response.getBody()) };
    }

    // INNER

    global class Input {
        @InvocableVariable(
            label='Endpoint URL' 
            description='The URL fragment of the REST endpoint starting with /. The Orgs base URL will be added' 
            required=true)
        global String urlIncludingParams;
        
        @InvocableVariable(
            label='HTTP Method' 
            description='The HTTP method to use' 
            required=true)
        global String httpMethod;
        
        @InvocableVariable(
            label='Request Body' 
            description='Payload data to be sent in the request body. Can be null if there is no body.' 
            required=false)
        global String requestBody;
    }

    global class Output {
        @InvocableVariable(
            label='Response Body' 
            description='Raw HTTP Response to be interpreted for Errors or Success' 
            required=true)
        global String responseBody;
        
        public Output(String body) {
            responseBody = body;
        }
    }
}