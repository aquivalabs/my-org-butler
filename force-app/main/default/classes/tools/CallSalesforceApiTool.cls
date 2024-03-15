// PMD False Positive: Calling regular Salesforce APIs can be done with Session Id
@SuppressWarnings('PMD.ApexSuggestUsingNamedCred') // AvoidUnauthorizedGetSessionIdInApex
public with sharing class CallSalesforceApiTool implements MyOrgButler.Tool {

    @InvocableMethod(label='Callout to Public Salesforce API endpoint on behalf of the current user'
                     description='For a given endpoint url, http method and body returns the raw response'
                     category='EinsteinCopilot'
                     callout=true)
    public static List<Output> execute(List<Input> inputs) {
        HttpRequest request = new HttpRequest();  
        request.setHeader('Authorization', 'Bearer ' + new SessionId().asString()); 
        request.setHeader('Content-Type', 'application/json');
        request.setEndpoint(Url.getOrgDomainURL().toExternalForm() + inputs[0].urlIncludingParams); 
        request.setMethod(inputs[0].httpMethod);   
        if(inputs[0].body != null) {
            request.setBody(inputs[0].body);
        }

        HttpResponse response = new Http().send(request);
        if(response.getStatusCode() != 200) {
            throw new ApplicationException('HTTP Request failed with code: ' + response.getStatusCode() + ' and message: ' + response.getBody() + '.');
        }

        Output result = new Output();
        result.rawResponse = response.getBody();
        return new List<Output>{ result };
        
    }

	public String execute(String jsonParameter) {
        JsonReader reader = new JsonReader(jsonParameter);
        
        Input input = new Input();
		input.urlIncludingParams = (String) reader.read('urlIncludingParams'); 
		input.httpMethod = (String) reader.read('httpMethod'); 
		
        try {
            input.body = (String) reader.read('body'); 
        } 
        catch(Exception ignored) {}

        return execute(new List<Input>{ input })[0].rawResponse;
    }

    // INNER

    public class Input {
        @InvocableVariable(description='The URL fragment of the REST endpoint starting with /. The Orgs base URL will be added.' required=true) 
        public String urlIncludingParams;

        @InvocableVariable(description='A HTTP Method for the Callout.' required=true) 
        public String httpMethod;

        @InvocableVariable(description='The optional body payload of the API Callout.' required=false)
        public String body;
    }
    
    public class Output {
        @InvocableVariable(description='The raw HTTP Response body in case of success or an error.' required=true) 
        public String rawResponse;
    }
}