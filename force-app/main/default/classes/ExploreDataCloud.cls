// Note: Agentforce requires Global; session auth needed to call Data Cloud metadata API
@SuppressWarnings('PMD.AvoidGlobalModifier, PMD.ApexSuggestUsingNamedCred')
global with sharing class ExploreDataCloud {

    @TestVisible
    private static List<HttpResponse> mockedResponses = new List<HttpResponse>();

    private static final String METADATA_ENDPOINT = '/services/data/v66.0/ssot/metadata';
    private static final Integer MAX_PAGES = 10;


    @InvocableMethod(label='MyOrgButler: Explore Data Cloud Schema'
                     description='Retrieve metadata about Data Cloud entities, fields, and relationships.')
    global static List<Output> execute(List<Input> inputs) {
        Input input = inputs[0];
        Output output = new Output();

        try {
            if(input.scope == 'details' || input.scope == 'relationships') {
                output.response = prepareEntityDetails(input.entityName, input.scope);
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
        Map<String, List<Map<String, String>>> entities = new Map<String, List<Map<String, String>>>();

        String url = METADATA_ENDPOINT + buildQueryParams(entityType, entityCategory);
        Integer pages = 0;
        Boolean truncated = false;

        while(url != null) {
            if(pages >= MAX_PAGES) {
                truncated = true;
                break;
            }

            HttpResponse response = callApi(url);
            Map<String, Object> parsed = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());

            addEntitiesTo(entities, (List<Object>) parsed.get('metadata'));

            url = (String) parsed.get('nextPageUrl');
            pages++;
        }

        Map<String, Object> result = new Map<String, Object>{ 'entities' => entities };
        if(truncated) {
            result.put('truncated', 'Results truncated at ' + MAX_PAGES + ' pages. Narrow with entityType or entityCategory filters.');
        }

        return JSON.serialize(result, true);
    }


    private static void addEntitiesTo(Map<String, List<Map<String, String>>> target, List<Object> metadata) {
        if(metadata == null) {
            return;
        }

        for(Object item : metadata) {
            Map<String, Object> entity = (Map<String, Object>) item;
            String name = (String) entity.get('name');
            String type = typeFromName(name);

            if(!target.containsKey(type)) {
                target.put(type, new List<Map<String, String>>());
            }

            Map<String, String> entry = new Map<String, String>{
                'name' => name,
                'category' => (String) entity.get('category')
            };
            String label = (String) entity.get('label');
            if(String.isNotBlank(label)) {
                entry.put('label', label);
            }
            String description = (String) entity.get('description');
            if(String.isNotBlank(description)) {
                entry.put('description', description);
            }

            target.get(type).add(entry);
        }
    }


    private static String typeFromName(String name) {
        String result = 'Other';

        if(name != null) {
            if(name.endsWith('__dlm')) {
                result = 'DataModelObject';
            }
            else if(name.endsWith('__dll')) {
                result = 'DataLakeObject';
            }
            else if(name.endsWith('__cio')) {
                result = 'CalculatedInsight';
            }
        }

        return result;
    }


    private static String prepareEntityDetails(String entityNames, String scope) {
        if(String.isBlank(entityNames)) {
            throw new DataCloudException('entityName is required for scope "' + scope + '"');
        }

        Map<String, Object> result = new Map<String, Object>();

        for(String raw : entityNames.split(',')) {
            String entityName = raw.trim();
            if(String.isBlank(entityName)) {
                continue;
            }

            Map<String, Object> entity = fetchEntity(entityName);
            result.put(entityName, projectEntity(entity, scope));
        }

        return JSON.serialize(result, true);
    }


    private static Map<String, Object> projectEntity(Map<String, Object> entity, String scope) {
        Map<String, Object> result = new Map<String, Object>();
        result.put('name', entity.get('name'));
        result.put('label', entity.get('label'));

        if(scope == 'details') {
            result.put('category', entity.get('category'));
            List<Object> fields = (List<Object>) entity.get('fields');
            if(fields != null) {
                result.put('fields', fields);
            }
            List<Object> primaryKeys = (List<Object>) entity.get('primaryKeys');
            if(primaryKeys != null) {
                result.put('primaryKeys', primaryKeys);
            }
        }

        List<Object> relationships = (List<Object>) entity.get('relationships');
        if(relationships != null) {
            result.put('relationships', relationships);
        }

        return result;
    }


    private static Map<String, Object> fetchEntity(String entityName) {
        String url = METADATA_ENDPOINT + '?entityName=' + EncodingUtil.urlEncode(entityName, 'UTF-8');
        HttpResponse response = callApi(url);

        Map<String, Object> parsed = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
        List<Object> metadata = (List<Object>) parsed.get('metadata');

        if(metadata == null || metadata.isEmpty()) {
            throw new DataCloudException('Entity not found: ' + entityName);
        }

        return (Map<String, Object>) metadata[0];
    }


    private static String buildQueryParams(String entityType, String entityCategory) {
        List<String> params = new List<String>();

        if(String.isNotBlank(entityType)) {
            params.add('entityType=' + EncodingUtil.urlEncode(entityType, 'UTF-8'));
        }
        if(String.isNotBlank(entityCategory)) {
            params.add('entityCategory=' + EncodingUtil.urlEncode(entityCategory, 'UTF-8'));
        }

        return params.isEmpty() ? '' : '?' + String.join(params, '&');
    }


    private static HttpResponse callApi(String endpoint) {
        HttpResponse result;

        if(Test.isRunningTest() && !mockedResponses.isEmpty()) {
            result = mockedResponses.remove(0);
        }
        else {
            HttpRequest request = new HttpRequest();
            request.setMethod('GET');
            request.setHeader('Authorization', 'Bearer ' + new SessionId().asString());
            request.setHeader('Content-Type', 'application/json');
            request.setEndpoint(toFullUrl(endpoint));

            result = new Http().send(request);
        }

        if(result.getStatusCode() >= 400) {
            throw new DataCloudException('Data Cloud API error (' + result.getStatusCode() + '): ' + result.getBody());
        }

        return result;
    }


    private static String toFullUrl(String endpoint) {
        return endpoint.startsWith('http')
            ? endpoint
            : Url.getOrgDomainURL().toExternalForm() + endpoint;
    }


    // INNER

    global class Input {
        @InvocableVariable(label='Scope' description='Mode of exploration: summary, details, or relationships' required=true)
        global String scope;

        @InvocableVariable(label='Entity Type' description='Optional filter: DataModelObject, DataLakeObject, or CalculatedInsight')
        global String entityType;

        @InvocableVariable(label='Entity Category' description='Optional filter: Profile, Engagement, or Related')
        global String entityCategory;

        @InvocableVariable(label='Entity Names' description='One or more Data Cloud entity API names, comma-separated (required for details or relationships scope)')
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
