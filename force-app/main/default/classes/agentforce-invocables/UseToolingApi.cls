public with sharing class UseToolingApi {

    public static HttpResponse mockedResponse = null;
    
    @InvocableMethod(label='MyOrgButler: Use Tooling API' description='Query, create, update, or delete records using the Tooling API. Supports SOQL queries and CRUD operations on Tooling API objects.')
    public static List<Output> execute(List<ToolingDescription> descriptions) {
        List<Output> result = new List<Output>();
        
        for(ToolingDescription tooling : descriptions) {
            HttpResponse response = mockedResponse != null ? mockedResponse : makeRequest(tooling);
            result.add(new Output(response.getBody()));
        }
        
        return result;
    }
    
    // PRIVATE
    
    private static HttpResponse makeRequest(ToolingDescription tooling) {
        HttpRequest request = new HttpRequest();
        request.setHeader('Authorization', 'Bearer ' + new SessionId().asString());
        request.setHeader('Content-Type', 'application/json');

        String baseUrl = URL.getOrgDomainUrl().toExternalForm() + '/services/data/v63.0/tooling';
        
        switch on tooling.action {
            when 'query' {
                request.setMethod('GET');
                request.setEndpoint(baseUrl + '/query/?q=' + EncodingUtil.urlEncode(tooling.soql, 'UTF-8'));
            }
            when 'create' {
                request.setMethod('POST');
                request.setEndpoint(baseUrl + '/sobjects/' + tooling.objectType);
                request.setBody(tooling.recordJson);
            }
            when 'update' {
                request.setMethod('PATCH');
                request.setEndpoint(baseUrl + '/sobjects/' + tooling.objectType + '/' + tooling.recordId);
                request.setBody(tooling.recordJson);
            }
            when 'delete' {
                request.setMethod('DELETE');
                request.setEndpoint(baseUrl + '/sobjects/' + tooling.objectType + '/' + tooling.recordId);
            }
            when else {
                throw new ApplicationException('Unsupported Tooling API action: ' + tooling.action);
            }
        }
        
        return new Http().send(request);
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