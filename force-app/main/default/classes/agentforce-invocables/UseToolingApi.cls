public with sharing class UseToolingApi {
    private static final String BASE_URL = '/services/data/v59.0/tooling';
    public static HttpResponse mockedResponse = null;
    
    @InvocableMethod(label='MyOrgButler: Use Tooling API' description='Query, create, update, or delete records using the Tooling API. Supports SOQL queries and CRUD operations on Tooling API objects.')
    public static List<Output> execute(List<ToolingDescription> descriptions) {
        List<Output> result = new List<Output>();
        
        for(ToolingDescription tooling : descriptions) {
            try {
                HttpResponse response = mockedResponse != null ? mockedResponse : makeRequest(tooling);
                handleErrors(response);
                result.add(new Output(response.getBody()));
            } catch(Exception ex) {
                throw new ApplicationException('Tooling API Action failed: ' + ex.getMessage(), ex);
            }
        }
        
        return result;
    }
    
    // PRIVATE
    
    private static HttpResponse makeRequest(ToolingDescription tooling) {
        HttpRequest request = new HttpRequest();
        request.setHeader('Authorization', 'Bearer ' + new SessionId().asString());
        request.setHeader('Content-Type', 'application/json');
        
        switch on tooling.action {
            when 'query' {
                request.setMethod('GET');
                request.setEndpoint(getBaseUrl() + '/query/?q=' + EncodingUtil.urlEncode(tooling.soql, 'UTF-8'));
            }
            when 'create' {
                request.setMethod('POST');
                request.setEndpoint(getBaseUrl() + '/sobjects/' + tooling.objectType);
                request.setBody(tooling.recordJson);
            }
            when 'update' {
                request.setMethod('PATCH');
                request.setEndpoint(getBaseUrl() + '/sobjects/' + tooling.objectType + '/' + tooling.recordId);
                request.setBody(tooling.recordJson);
            }
            when 'delete' {
                request.setMethod('DELETE');
                request.setEndpoint(getBaseUrl() + '/sobjects/' + tooling.objectType + '/' + tooling.recordId);
            }
            when else {
                throw new ApplicationException('Unsupported Tooling API action: ' + tooling.action);
            }
        }
        
        return new Http().send(request);
    }
    
    private static void handleErrors(HttpResponse response) {
        Integer statusCode = response.getStatusCode();
        if (statusCode < 200 || statusCode >= 300) {
            String error = 'Tooling API error: HTTP ' + statusCode + ' - ' + response.getBody();
            throw new ApplicationException(error);
        }
    }
    
    private static String getBaseUrl() {
        return URL.getOrgDomainUrl().toExternalForm() + BASE_URL;
    }
    
    // INNER
    
    public class ToolingDescription {
        @InvocableVariable(label='Action' description='The Tooling API action to perform: query, create, update, delete' required=true)
        public String action;
        
        @InvocableVariable(label='Object Type' description='The Tooling API object type (e.g., ApexClass, CustomField)' required=false)
        public String objectType;
        
        @InvocableVariable(label='SOQL Query' description='The SOQL query to execute (for query action)' required=false)
        public String soql;
        
        @InvocableVariable(label='Record JSON' description='JSON representation of the record to create or update' required=false)
        public String recordJson;
        
        @InvocableVariable(label='Record Id' description='Id of the record to update or delete' required=false)
        public String recordId;
    }
    
    public class Output {
        @InvocableVariable(label='Response Body' description='Raw HTTP Response to be interpreted for Errors or Success')
        public String responseBody;
        
        public Output(String body) {
            responseBody = body;
        }
    }
}