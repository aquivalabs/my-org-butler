// PMD False Positives: Agentforce requires Global
@SuppressWarnings('PMD.AvoidGlobalMethod')
global with sharing class CallToolingApi {

    public static HttpResponse mockedResponse = null;
    
    @InvocableMethod(label='MyOrgButler: Use Tooling API' description='Query, create, update, or delete records using the Tooling API. Supports SOQL queries and CRUD operations on Tooling API objects.')
    global static List<Output> execute(List<ToolingDescription> descriptions) {
        List<Output> result = new List<Output>();
        
        for(ToolingDescription tooling : descriptions) {
            HttpResponse response = mockedResponse != null ? mockedResponse : makeRequest(tooling);
            result.add(new Output(response.getBody()));
        }
        
        return result;
    }
    
    // PUBLIC
    
    public static List<Map<String, Object>> query(String soql) {
        List<Map<String, Object>> results = new List<Map<String, Object>>();
        
        ToolingDescription tooling = new ToolingDescription();
        tooling.action = 'query';
        tooling.soql = soql;
        
        List<Output> outputs = execute(new List<ToolingDescription>{tooling});
        String responseBody = outputs[0].responseBody;
        
        Map<String, Object> responseMap = (Map<String, Object>)JSON.deserializeUntyped(responseBody);
        if(responseMap.containsKey('records')) {
            List<Object> records = (List<Object>)responseMap.get('records');
            for(Object record : records) {
                results.add((Map<String, Object>)record);
            }
        }
        
        return results;
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
    
    global class ToolingDescription {
        @InvocableVariable(label='Action' description='The Tooling API action to perform: query, create, update, delete' required=true)
        global String action;
        
        @InvocableVariable(label='Object Type' description='The Tooling API object type (e.g., ApexClass, CustomField)' required=false)
        global String objectType;
        
        @InvocableVariable(label='SOQL Query' description='The SOQL query to execute (for query action)' required=false)
        global String soql;
        
        @InvocableVariable(label='Record JSON' description='JSON representation of the record to create or update' required=false)
        global String recordJson;
        
        @InvocableVariable(label='Record Id' description='Id of the record to update or delete' required=false)
        public String recordId;
    }
    
    global class Output {
        @InvocableVariable(label='Response Body' description='Raw HTTP Response to be interpreted for Errors or Success')
        global String responseBody;
        
        public Output(String body) {
            responseBody = body;
        }
    }
}