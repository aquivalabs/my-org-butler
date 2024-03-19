// PMD False Positive: Calling regular Salesforce APIs can be done with Session Id
@SuppressWarnings('PMD.ApexSuggestUsingNamedCred') // AvoidUnauthorizedGetSessionIdInApex
public with sharing class CallSalesforceApiTool implements MyOrgButler.Tool {

	public String execute(String jsonParameter) {
        JsonParse parser = new JsonParse(jsonParameter);

        HttpRequest request = new HttpRequest();  
        request.setHeader('Authorization', 'Bearer ' + new SessionId().asString()); 
        request.setHeader('Content-Type', 'application/json');
        request.setEndpoint(Url.getOrgDomainURL().toExternalForm() + parser.get('urlIncludingParams').getStringValue()); 
        request.setMethod(parser.get('httpMethod').getStringValue());   

        String body = parser.get('body').getStringValue();
        if(String.isNotEmpty(body)) {
            request.setBody(body);
        }

        HttpResponse response = new Http().send(request);
        if(response.getStatusCode() >= 300) {
            throw new ApplicationException('HTTP Request failed with code: ' + response.getStatusCode() + ' and message: ' + response.getBody() + '.');
        }

        return response.getBody();
    }
}