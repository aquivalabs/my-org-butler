// PMD False Positive: Calling regular Salesforce APIs can be done with Session Id
@SuppressWarnings('PMD.ApexSuggestUsingNamedCred')
public with sharing class CallSalesforceApiTool extends MyOrgButler.Tool {

	public override String execute(String jsonParameter) {
        JsonParse parser = new JsonParse(jsonParameter);

        Input input = new Input();
        input.httpMethod = parser.get('httpMethod').getStringValue();
        input.urlIncludingParams = parser.get('urlIncludingParams').getStringValue();
        input.requestBody = parser.get('body').getStringValue();

        List<Output> result = execute(new List<Input>{ input });
        return result[0].responseBody;
    }

    @InvocableMethod(
        label='MyOrgButler: Call Salesforce API'
        description='Call an official public Salesforce API REST endpoint')
    public static List<Output> execute(List<Input> input) {
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

    public class Input {
        @InvocableVariable(
            label='Endpoint URL' 
            description='The URL fragment of the REST endpoint starting with /. The Orgs base URL will be added' 
            required=true)
        public String urlIncludingParams;
        
        @InvocableVariable(
            label='HTTP Method' 
            description='The HTTP method to use' 
            required=true)
        public String httpMethod;
        
        @InvocableVariable(
            label='Request Body' 
            description='Payload data to be sent in the request body. Can be null if there is no body.' 
            required=true)
        public String requestBody;
    }

    public class Output {
        @InvocableVariable(
            label='Response Body' 
            description='Raw HTTP Response to be interpreted for Errors or Success' 
            required=true)
        public String responseBody;
        
        public Output(String body) {
            responseBody = body;
        }
    }
}