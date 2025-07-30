@SuppressWarnings('PMD.AvoidGlobalMethod')
global with sharing class ExploreOrgSchema {

    private static final Map<String, SObjectType> GLOBAL_DESCRIBE = Schema.getGlobalDescribe();
    
    @InvocableMethod(label='MyOrgButler: Explore Org Data Model' 
                     description='Retrieve metadata about objects, fields and relationships in the org.')
    global static List<Output> execute(List<Input> inputs) {
        Input input = inputs[0];
        
        // Process input filters after invocation
        Set<String> namespaceFilter = parseNamespaces(input.namespaceFilter);
        Set<String> objectFilter = parseObjects(input.objectFilter);
        
        Output output = new Output();
        output.response = (input.scope == 'details') 
            ? prepareDetails(objectFilter, namespaceFilter)
            : prepareSummary(namespaceFilter);
            
        return new List<Output>{ output };
    }

    // PRIVATE METHODS

    private static String prepareSummary(Set<String> namespaceFilter) {
        Map<String, NamespaceInfo> namespaceMap = loadNamespaceInfo();
        Map<String, String> objectDescriptions = loadObjectDescriptions();
        
        // Group objects by namespace
        for (String objectKey : GLOBAL_DESCRIBE.keySet()) {
            DescribeSObjectResult objDescribe = GLOBAL_DESCRIBE.get(objectKey).getDescribe();
            
            if (!objDescribe.isCustom()) {
                continue;
            }
            
            String namespace = extractNamespace(objDescribe.getName());
            
            // Apply namespace filter
            if (!namespaceFilter.isEmpty() && !namespaceFilter.contains(namespace)) {
                continue;
            }
            
            // Ensure namespace exists in map
            if (!namespaceMap.containsKey(namespace)) {
                namespaceMap.put(namespace, createDefaultNamespaceInfo(namespace));
            }
            
            // Add object to namespace
            ObjectSummary objSummary = new ObjectSummary(
                objDescribe.getName(),
                objDescribe.getLabel(),
                objectDescriptions.get(objDescribe.getName())
            );
            namespaceMap.get(namespace).objects.add(objSummary);
        }
        
        return JSON.serialize(namespaceMap.values(), true);
    }

    private static String prepareDetails(Set<String> objectFilter, Set<String> namespaceFilter) {
        Map<String, ObjectDetails> result = new Map<String, ObjectDetails>();
        Map<String, String> objectDescriptions = loadObjectDescriptions();
        
        for (String objectName : objectFilter) {
            String cleanObjectName = objectName.trim();
            SObjectType objType = GLOBAL_DESCRIBE.get(cleanObjectName);
            
            if (objType != null) {
                result.put(cleanObjectName, new ObjectDetails(objType, objectDescriptions, namespaceFilter));
            }
        }
        
        return JSON.serialize(result, true);
    }

    private static Map<String, String> loadObjectDescriptions() {
        Map<String, String> result = new Map<String, String>();
        
        List<Map<String, Object>> records = CallToolingApi.query(
            'SELECT DeveloperName, Description FROM CustomObject'
        );
        
        for (Map<String, Object> record : records) {
            String apiName = (String) record.get('DeveloperName');
            String description = (String) record.get('Description');
            if (apiName != null) {
                result.put(apiName, description);
            }
        }
        
        return result;
    }

    private static Map<String, NamespaceInfo> loadNamespaceInfo() {
        Map<String, NamespaceInfo> result = new Map<String, NamespaceInfo>();
        
        List<Map<String, Object>> records = CallToolingApi.query(
            'SELECT SubscriberPackage.NamespacePrefix, SubscriberPackage.Name, SubscriberPackage.Description ' +
            'FROM InstalledSubscriberPackage'
        );
        
        for (Map<String, Object> record : records) {
            String namespace = (String) record.get('SubscriberPackage.NamespacePrefix');
            String packageName = (String) record.get('SubscriberPackage.Name');
            String packageDesc = (String) record.get('SubscriberPackage.Description');
            
            if (namespace != null) {
                result.put(namespace, new NamespaceInfo(namespace, packageName, packageDesc));
            }
        }
        
        return result;
    }

    // UTILITY METHODS

    private static String extractNamespace(String objectName) {
        if (String.isBlank(objectName) || !objectName.contains('__')) {
            return null;
        }
        return objectName.split('__')[0];
    }

    private static Set<String> parseNamespaces(String namespaceFilter) {
        if (String.isBlank(namespaceFilter)) {
            return new Set<String>();
        }
        
        Set<String> result = new Set<String>();
        for (String ns : namespaceFilter.split(',')) {
            String cleanNs = ns.trim();
            if (String.isNotBlank(cleanNs)) {
                result.add(cleanNs);
            }
        }
        return result;
    }

    private static Set<String> parseObjects(String objectFilter) {
        if (String.isBlank(objectFilter)) {
            return new Set<String>();
        }
        
        Set<String> result = new Set<String>();
        for (String obj : objectFilter.split(',')) {
            String cleanObj = obj.trim();
            if (String.isNotBlank(cleanObj)) {
                result.add(cleanObj);
            }
        }
        return result;
    }

    private static NamespaceInfo createDefaultNamespaceInfo(String namespace) {
        return new NamespaceInfo(
            namespace, 
            namespace + ' Package', 
            'Custom objects from ' + (namespace != null ? namespace : 'unmanaged') + ' namespace'
        );
    }

    // INNER CLASSES

    global class Input {
        @InvocableVariable(label='Scope' description='Mode of metadata exploration: summary or details')
        global String scope;

        @InvocableVariable(label='Namespace Filter' description='Optional namespace prefix to limit objects by package')
        global String namespaceFilter;

        @InvocableVariable(label='Object API Names' description='Comma-separated list of object API names to explore')
        global String objectFilter;
    }

    global class Output {
        @InvocableVariable(label='Response as JSON' description='Serialized JSON output of schema exploration')
        global String response;
    }

    class NamespaceInfo {
        String namespace;
        String packageName;
        String packageDescription;
        List<ObjectSummary> objects = new List<ObjectSummary>();

        NamespaceInfo(String namespace, String packageName, String packageDescription) {
            this.namespace = namespace;
            this.packageName = packageName;
            this.packageDescription = packageDescription;
        }
    }

    class ObjectSummary {
        String apiName;
        String label;
        String description;

        ObjectSummary(String apiName, String label, String description) {
            this.apiName = apiName;
            this.label = label;
            this.description = description;
        }
    }

    class ObjectDetails {
        String apiName;
        String label;
        String description;
        String namespace;
        Map<String, FieldDetails> fields = new Map<String, FieldDetails>();
        List<String> childRelationships = new List<String>();

        ObjectDetails(SObjectType objType, Map<String, String> objectDescriptions, Set<String> namespaceFilter) {
            DescribeSObjectResult describe = objType.getDescribe();
            this.apiName = describe.getName();
            this.label = describe.getLabel();
            this.namespace = extractNamespace(describe.getName());
            this.description = objectDescriptions.get(describe.getName());

            // Add fields
            for (SObjectField field : describe.fields.getMap().values()) {
                DescribeFieldResult fieldDescribe = field.getDescribe();
                fields.put(fieldDescribe.getName(), new FieldDetails(fieldDescribe));
            }

            // Add child relationships with namespace filtering
            for (ChildRelationship relationship : describe.getChildRelationships()) {
                String childObjectName = relationship.getChildSObject().getDescribe().getName();
                String childNamespace = extractNamespace(childObjectName);
                
                if (namespaceFilter.isEmpty() || namespaceFilter.contains(childNamespace)) {
                    childRelationships.add(childObjectName);
                }
            }
        }
    }

    class FieldDetails {
        String label;
        String type;
        Boolean required;
        String helpText;
        List<String> references;
        String relationshipName;
        // START: Added property for picklist values
        List<Map<String, String>> picklistValues; 
        // END: Added property for picklist values

        FieldDetails(DescribeFieldResult fieldDescribe) {
            this.label = fieldDescribe.getLabel();
            this.type = String.valueOf(fieldDescribe.getType());
            this.required = !fieldDescribe.isNillable();
            this.helpText = fieldDescribe.getInlineHelpText();

            if (fieldDescribe.getType() == DisplayType.REFERENCE) {
                this.references = new List<String>();
                for (SObjectType refType : fieldDescribe.getReferenceTo()) {
                    references.add(refType.getDescribe().getName());
                }
                this.relationshipName = fieldDescribe.getRelationshipName();
            }
            
            if (fieldDescribe.getType() == DisplayType.PICKLIST || fieldDescribe.getType() == DisplayType.MULTIPICKLIST) {
                this.picklistValues = new List<Map<String, String>>();
                for (Schema.PicklistEntry entry : fieldDescribe.getPicklistValues()) {
                    picklistValues.add(new Map<String, String>{
                        'label' => entry.getLabel(),
                        'value' => entry.getValue()
                    });
                }
            }
        }
    }
}