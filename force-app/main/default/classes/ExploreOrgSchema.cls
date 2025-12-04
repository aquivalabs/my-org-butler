// Note: Agentforce requires Global
@SuppressWarnings('PMD.AvoidGlobalModifier')
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
        if (input.scope == 'details' || input.scope == 'relationships') {
            output.response = prepareDetails(objectFilter, namespaceFilter, input.scope);
        } else {
            output.response = prepareSummary(namespaceFilter);
        }
            
        return new List<Output>{ output };
    }

    // PRIVATE METHODS

    private static String prepareSummary(Set<String> namespaceFilter) {
        Map<String, NamespaceInfo> namespaceMap = loadNamespaceInfo();
        Map<String, String> objectDescriptions = loadObjectDescriptions();
        
        for (String objectKey : GLOBAL_DESCRIBE.keySet()) {
            DescribeSObjectResult objDescribe = GLOBAL_DESCRIBE.get(objectKey).getDescribe();
            
            if (!objDescribe.isCustom()) {
                continue;
            }
            
            String namespace = extractNamespace(objDescribe.getName());
            
            if (!namespaceFilter.isEmpty() && !namespaceFilter.contains(namespace)) {
                continue;
            }
            
            if (!namespaceMap.containsKey(namespace)) {
                namespaceMap.put(namespace, createDefaultNamespaceInfo(namespace));
            }
            
            ObjectSummary objSummary = new ObjectSummary(
                objDescribe.getName(),
                objDescribe.getLabel(),
                objectDescriptions.get(objDescribe.getName())
            );
            namespaceMap.get(namespace).objects.add(objSummary);
        }
        
        return JSON.serialize(namespaceMap.values(), true);
    }

    private static String prepareDetails(Set<String> objectFilter, Set<String> namespaceFilter, String scope) {
        Map<String, ObjectDetails> result = new Map<String, ObjectDetails>();
        Map<String, String> objectDescriptions = loadObjectDescriptions();
        
        for (String objectName : objectFilter) {
            String cleanObjectName = objectName.trim();
            SObjectType objType = GLOBAL_DESCRIBE.get(cleanObjectName);
            
            if (objType != null) {
                result.put(cleanObjectName, new ObjectDetails(objType, objectDescriptions, namespaceFilter, scope));
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
        String result = null;

        if (String.isNotBlank(objectName) && objectName.contains('__')) {
            result = objectName.split('__')[0];
        }

        return result;
    }

    private static Set<String> parseNamespaces(String namespaceFilter) {
        Set<String> result = new Set<String>();

        if (String.isNotBlank(namespaceFilter)) {
            for (String ns : namespaceFilter.split(',')) {
                String cleanNs = ns.trim();
                if (String.isNotBlank(cleanNs)) {
                    result.add(cleanNs);
                }
            }
        }

        return result;
    }

    private static Set<String> parseObjects(String objectFilter) {
        Set<String> result = new Set<String>();

        if (String.isNotBlank(objectFilter)) {
            for (String obj : objectFilter.split(',')) {
                String cleanObj = obj.trim();
                if (String.isNotBlank(cleanObj)) {
                    result.add(cleanObj);
                }
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
        @InvocableVariable(label='Scope' description='Mode of metadata exploration: summary, details, or relationships')
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

    public class NamespaceInfo {
        public String namespace;
        public String packageName;
        public String packageDescription;
        public List<ObjectSummary> objects = new List<ObjectSummary>();

        NamespaceInfo(String namespace, String packageName, String packageDescription) {
            this.namespace = namespace;
            this.packageName = packageName;
            this.packageDescription = packageDescription;
        }
    }

    public class ObjectSummary {
        public String apiName;
        public String label;
        public String description;

        ObjectSummary(String apiName, String label, String description) {
            this.apiName = apiName;
            this.label = label;
            this.description = description;
        }
    }

    // Note: 4 parameters is acceptable here - introducing a wrapper would add unnecessary complexity
    @SuppressWarnings('PMD.ExcessiveParameterList')
    public class ObjectDetails {
        public String apiName;
        public String label;
        public String description;
        public String namespace;
        public Map<String, FieldDetails> fields;
        public List<String> childRelationships;
        public List<String> parentRelationships;


        ObjectDetails(SObjectType objType, Map<String, String> descriptions, Set<String> nsFilter, String scope) {
            DescribeSObjectResult describe = objType.getDescribe();
            
            apiName = describe.getName();
            label = describe.getLabel();
            namespace = extractNamespace(apiName);
            description = descriptions.get(apiName);

            if (scope == 'details') {
                fields = buildFieldsMap(describe);
            }
            
            if (scope == 'details' || scope == 'relationships') {
                childRelationships = buildChildRelationships(describe, nsFilter);
                parentRelationships = buildParentRelationships(describe);
            }
        }


        private Map<String, FieldDetails> buildFieldsMap(DescribeSObjectResult describe) {
            Map<String, FieldDetails> result = new Map<String, FieldDetails>();

            for (SObjectField field : describe.fields.getMap().values()) {
                DescribeFieldResult fieldDescribe = field.getDescribe();
                result.put(fieldDescribe.getName(), new FieldDetails(fieldDescribe));
            }

            return result;
        }


        private List<String> buildChildRelationships(DescribeSObjectResult describe, Set<String> nsFilter) {
            List<String> result = new List<String>();

            for (ChildRelationship rel : describe.getChildRelationships()) {
                String childName = rel.getChildSObject().getDescribe().getName();
                String childNs = extractNamespace(childName);
                
                if ((nsFilter.isEmpty() || nsFilter.contains(childNs)) && rel.getRelationshipName() != null) {
                    result.add(rel.getRelationshipName());
                }
            }

            return result;
        }


        private List<String> buildParentRelationships(DescribeSObjectResult describe) {
            List<String> result = new List<String>();

            for (SObjectField field : describe.fields.getMap().values()) {
                DescribeFieldResult fd = field.getDescribe();
                if (fd.getType() == DisplayType.REFERENCE && String.isNotBlank(fd.getRelationshipName())) {
                    String target = fd.getReferenceTo()[0].getDescribe().getName();
                    result.add(fd.getRelationshipName() + ' (to ' + target + ')');
                }
            }

            return result;
        }
    }

    public class FieldDetails {
        public String label;
        public String type;
        public Boolean required;
        public String helpText;
        public List<String> references;
        public String relationshipName;
        public List<Map<String, String>> picklistValues; 

        FieldDetails(DescribeFieldResult fieldDescribe) {
            label = fieldDescribe.getLabel();
            type = String.valueOf(fieldDescribe.getType());
            required = !fieldDescribe.isNillable();
            helpText = fieldDescribe.getInlineHelpText();

            if (fieldDescribe.getType() == DisplayType.REFERENCE) {
                references = new List<String>();
                for (SObjectType refType : fieldDescribe.getReferenceTo()) {
                    references.add(refType.getDescribe().getName());
                }
                relationshipName = fieldDescribe.getRelationshipName();
            }
            
            if (fieldDescribe.getType() == DisplayType.PICKLIST || fieldDescribe.getType() == DisplayType.MULTIPICKLIST) {
                picklistValues = new List<Map<String, String>>();
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