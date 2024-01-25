// PMD False Positive: Calling regular Salesforce APIs can be done with Session Id
@SuppressWarnings('PMD.ApexSuggestUsingNamedCred') // AvoidUnauthorizedGetSessionIdInApex
public with sharing class CallSalesforceApiTool implements MyOrgButler.Tool {
    
    public String execute(String jsonParameter) {
        JsonParse params = new JSONParse(jsonParameter);

        HttpRequest request = new HttpRequest();  
        request.setEndpoint(baseUrl() + params.get('urlIncludingParams').getStringValue()); 
        request.setMethod(params.get('httpMethod').getStringValue());   
        request.setHeader('Authorization', 'OAuth ' + UserInfo.getSessionId());        
        request.setHeader('Authorization', 'Bearer ' + UserInfo.getSessionId()); 
        request.setHeader('Content-Type', 'application/json');
        setBody(request, params);

        HttpResponse response = new Http().send(request);
        if(response.getStatusCode() != 200) {
            throw new ApplicationException('HTTP Request failed with code: ' + response.getStatusCode() + ' and message: ' + response.getBody() + '.');
        }

        return response.getBody();
    }

    // PRIVATE 

    private void setBody(HttpRequest request, JsonParse params) {
        try {
            request.setBody(params.get('body').getStringValue());
        } 
        catch(Exception ignored) {}
    }

    private String baseUrl() {
        return URL.getSalesforceBaseUrl().toExternalForm();
    }
}