// Note: Agentforce requires Global; session auth needed to call Data Cloud metadata API
@SuppressWarnings('PMD.AvoidGlobalModifier, PMD.ApexSuggestUsingNamedCred')
global with sharing class ExploreDataCloud {

    public static HttpResponse mockedResponse = null;

    private static final String METADATA_ENDPOINT = '/services/data/v66.0/ssot/metadata';

    @InvocableMethod(label='MyOrgButler: Explore Data Cloud Schema'
                     description='Retrieve metadata about Data Cloud entities, fields, and relationships.')
    global static List<Output> execute(List<Input> inputs) {
        Input input = inputs[0];
        Output output = new Output();

        try {
            if(String.isNotBlank(input.entityName) && input.scope == 'relationships') {
                output.response = prepareRelationships(input.entityName);
            }
            else if(String.isNotBlank(input.entityName) && input.scope == 'details') {
                output.response = prepareDetails(input.entityName);
            }
            else {
                output.response = prepareSummary(input.entityType, input.entityCategory);
            }
        }
        catch(Exception ex) {
            Map<String, Object> exceptionInfo = new Map<String, Object>{
                'message' => ex.getMessage(),
                'typeName' => ex.getTypeName(),
                'stackTrace' => ex.getStackTraceString()
            };
            output.response = JSON.serialize(exceptionInfo);
        }

        return new List<Output>{ output };
    }


    // PRIVATE

    private static String prepareSummary(String entityType, String entityCategory) {
        String url = METADATA_ENDPOINT + buildQueryParams(entityType, entityCategory);
        HttpResponse response = callApi(url);

        Map<String, Object> parsed = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
        List<Object> metadata = (List<Object>) parsed.get('metadata');

        Map<String, List<Map<String, String>>> result = new Map<String, List<Map<String, String>>>();

        for(Object item : metadata) {
            Map<String, Object> entity = (Map<String, Object>) item;
            String type = (String) entity.get('type') ?? 'Other';
            String name = (String) entity.get('name');
            String label = (String) entity.get('label');
            String category = (String) entity.get('category');
            String description = (String) entity.get('description');

            if(!result.containsKey(type)) {
                result.put(type, new List<Map<String, String>>());
            }

            Map<String, String> entry = new Map<String, String>{
                'name' => name,
                'label' => label,
                'category' => category
            };
            if(String.isNotBlank(description)) {
                entry.put('description', description);
            }

            result.get(type).add(entry);
        }

        return JSON.serialize(result, true);
    }


    private static String prepareDetails(String entityName) {
        Map<String, Object> entity = fetchEntity(entityName);

        Map<String, Object> result = new Map<String, Object>();
        result.put('name', entity.get('name'));
        result.put('label', entity.get('label'));
        result.put('category', entity.get('category'));

        List<Object> fields = (List<Object>) entity.get('fields');
        if(fields != null) {
            result.put('fields', fields);
        }

        List<Object> relationships = (List<Object>) entity.get('relationships');
        if(relationships != null) {
            result.put('relationships', relationships);
        }

        List<Object> primaryKeys = (List<Object>) entity.get('primaryKeys');
        if(primaryKeys != null) {
            result.put('primaryKeys', primaryKeys);
        }

        return JSON.serialize(result, true);
    }


    private static String prepareRelationships(String entityName) {
        Map<String, Object> entity = fetchEntity(entityName);

        Map<String, Object> result = new Map<String, Object>();
        result.put('name', entity.get('name'));

        List<Object> relationships = (List<Object>) entity.get('relationships');
        if(relationships != null) {
            result.put('relationships', relationships);
        }

        return JSON.serialize(result, true);
    }


    private static Map<String, Object> fetchEntity(String entityName) {
        String url = METADATA_ENDPOINT + '?entityName=' + EncodingUtil.urlEncode(entityName, 'UTF-8');
        HttpResponse response = callApi(url);

        Map<String, Object> parsed = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
        List<Object> metadata = (List<Object>) parsed.get('metadata');

        Map<String, Object> result = (Map<String, Object>) metadata[0];

        return result;
    }


    private static String buildQueryParams(String entityType, String entityCategory) {
        List<String> params = new List<String>();

        if(String.isNotBlank(entityType)) {
            params.add('entityType=' + EncodingUtil.urlEncode(entityType, 'UTF-8'));
        }
        if(String.isNotBlank(entityCategory)) {
            params.add('entityCategory=' + EncodingUtil.urlEncode(entityCategory, 'UTF-8'));
        }

        String result = params.isEmpty() ? '' : '?' + String.join(params, '&');

        return result;
    }


    private static HttpResponse callApi(String endpoint) {
        HttpResponse result = mockedResponse;

        if(result == null) {
            HttpRequest request = new HttpRequest();
            request.setMethod('GET');
            request.setHeader('Authorization', 'Bearer ' + new SessionId().asString());
            request.setHeader('Content-Type', 'application/json');
            request.setEndpoint(Url.getOrgDomainURL().toExternalForm() + endpoint);

            result = new Http().send(request);
        }

        if(result.getStatusCode() >= 400) {
            throw new DataCloudException('Data Cloud API error (' + result.getStatusCode() + '): ' + result.getBody());
        }

        return result;
    }


    // INNER

    global class Input {
        @InvocableVariable(label='Scope' description='Mode of exploration: summary, details, or relationships' required=true)
        global String scope;

        @InvocableVariable(label='Entity Type' description='Optional filter: DataModelObject, DataLakeObject, or CalculatedInsight')
        global String entityType;

        @InvocableVariable(label='Entity Category' description='Optional filter: Profile, Engagement, or Related')
        global String entityCategory;

        @InvocableVariable(label='Entity Name' description='Exact API name of a Data Cloud entity (used with details or relationships scope)')
        global String entityName;

        // Note: Empty constructor required for Invocable Methods deserialization
        @SuppressWarnings('PMD.EmptyStatementBlock')
        global Input() {}
    }

    global class Output {
        @InvocableVariable(label='Response as JSON' description='Serialized JSON of Data Cloud schema exploration, or exception object on error')
        global String response;
    }

    public class DataCloudException extends Exception {}
}
