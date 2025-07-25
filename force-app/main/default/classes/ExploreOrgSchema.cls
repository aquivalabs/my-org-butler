// PMD False Positives: Agentforce requires Global
@SuppressWarnings('PMD.AvoidGlobalMethod')
global with sharing class ExploreOrgSchema {

    private static final Map<String, Schema.SObjectType> DESCRIBE = Schema.getGlobalDescribe();
    private static final Map<String, String> OBJECT_SEMANTICS = loadObjectSemantics();

    // PUBLIC

    @InvocableMethod(label='MyOrgButler: Explore Org Data Model' description='Retrieve metadata about objects, fields and relationships in the org.')
    global static List<Output> execute(List<Input> inputs) {
        Input input = inputs[0];
        
        Output output = new Output();
        output.response = (input.scope == 'details') ? prepareDetails(input) : prepareSummary(input);
        
        return new List<Output>{ output };
    }

    // PRIVATE

    private static String prepareSummary(Input input) {
        Map<String, NamespaceGroup> result = new Map<String, NamespaceGroup>();
        Set<String> filter = (input.namespaceFilter == null) ? new Set<String>() : new Set<String>( input.namespaceFilter.split(',') );

        for(String key : DESCRIBE.keySet()) {
            Schema.DescribeSObjectResult describeResult = DESCRIBE.get(key).getDescribe();
            String ns = getNamespace(describeResult.getName());
            if (describeResult.isCustom()) {

                if (filter.isEmpty() || filter.contains(ns)) {
                    System.debug(LoggingLevel.ERROR, 'prepareSummary: custom object is in relevant namespace: ns=' + ns);
                    if(!result.containsKey(ns)) {
                        result.put(ns, new NamespaceGroup(ns, null));
                    }
                    result.get(ns).objects.add(new ObjectSummary(describeResult));
                }
            }
        }

        return JSON.serialize(result.values());
    }

    private static String prepareDetails(Input input) {
        Map<String, ObjectDetails> result = new Map<String, ObjectDetails>();

        for (String objectName : input.objectFilter.split(',')) {
            Schema.SObjectType type = DESCRIBE.get(objectName.trim());
            result.put(objectName, new ObjectDetails(type));
        }

        return JSON.serialize(result);
    }

    private static Map<String, String> loadObjectSemantics() {
        Map<String, String> result = new Map<String, String>();
        
        for (Map<String, Object> record : CallToolingApi.query('SELECT DeveloperName, Description FROM CustomObject')) {
            String apiName = (String)record.get('DeveloperName');
            String description = (String)record.get('Description');
            result.put(apiName, description);
        }
        return result;
    }

    private static String getNamespace(String name) {
        return name.contains('__') ? name.split('__')[0] : null;
    }

    // INNER

    global class Input {
        @InvocableVariable(label='Scope' description='Mode of metadata exploration: allObjects or objectDetails')
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

    class NamespaceGroup {
        String namespace;
        PackageInfo packageInfo;
        List<ObjectSummary> objects = new List<ObjectSummary>();
        
        NamespaceGroup(String namespace, PackageInfo pck) {
            this.namespace = namespace;
            this.packageInfo = pck;
        }
    }

    class PackageInfo {
        String name;
        String description;

        PackageInfo(String name, String description) {
            this.name = name;
            this.description = description;
        }
}

    class ObjectSummary {
        String apiName;
        String label;
        String description;

        ObjectSummary(Schema.DescribeSObjectResult describe) {
            apiName = describe.getName();
            label = describe.getLabel();
            description = OBJECT_SEMANTICS.get(describe.getName());
        }
    }

    class ObjectDetails {
        String apiName;
        String label;
        String description;
        String namespace;
        Map<String, FieldDetails> fields = new Map<String, FieldDetails>();
        List<String> childRelationships = new List<String>();

        ObjectDetails(Schema.SObjectType type) {
            Schema.DescribeSObjectResult describe = type.getDescribe();
            apiName = describe.getName();
            label = describe.getLabel();
            namespace = getNamespace(describe.getName());
            description = OBJECT_SEMANTICS.get(describe.getName());

            for (Schema.SObjectField field : describe.fields.getMap().values()) {
                fields.put(field.getDescribe().getName(), new FieldDetails(field.getDescribe()));
            }

            for (Schema.ChildRelationship relationship : describe.getChildRelationships()) {
                childRelationships.add(relationship.getChildSObject().toString());
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

        FieldDetails(Schema.DescribeFieldResult describe) {
            label = describe.getLabel();
            type = String.valueOf(describe.getType());
            required = !describe.isNillable();
            helpText = describe.getInlineHelpText();

            if (describe.getType() == Schema.DisplayType.REFERENCE) {
                references = new List<String>();

                for (Schema.SObjectType r : describe.getReferenceTo()) {
                    references.add(r.getDescribe().getName());
                }

                relationshipName = describe.getRelationshipName();
            }
        }
    }
}