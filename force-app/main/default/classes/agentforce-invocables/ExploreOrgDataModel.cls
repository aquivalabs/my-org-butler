public with sharing class ExploreOrgDataModel {
    
    @InvocableMethod(label='MyOrgButler: Explore Org Data Model' description='Retrieve metadata about objects, fields and relationships in the org.')
    public static List<Output> investigateSchema(List<Input> requests) {
        List<Output> results = new List<Output>();
        
        for(Input request : requests) {
            String response = '';
            
            if(request.scope == 'allObjects') {
                response = getAllObjects();
            } 
            else if(request.scope == 'objectDetails') {
                response = getObjectFields(request.objects);
            }
            else {
                throw new ApplicationException('Invalid scope value. Must be either "allObjects" or "objectDetails".');
            }
            
            results.add(new Output(response));
        }
        
        return results;
    }

    // PRIVATE
    
    private static String getAllObjects() {
        List<String> lines = new List<String>();
        
        Map<String, Schema.SObjectType> globalDescribe = Schema.getGlobalDescribe();
        for(String objectName : globalDescribe.keySet()) {
            Schema.DescribeSObjectResult describeResult = globalDescribe.get(objectName).getDescribe();
            if(describeResult.isCustom()) {
                lines.add(describeResult.getName());
            }
        }
        lines.sort();
        
        return String.join(lines, '\n');
    }

    private static String getObjectFields(String objectNames) {
        List<String> lines = new List<String>();
        
        for(String objectName : getObjectsToDescribe(objectNames)) {
            Schema.SObjectType sObjectType = Schema.getGlobalDescribe().get(objectName);
           
            if(sObjectType != null) {
                Schema.DescribeSObjectResult describe = sObjectType.getDescribe();
                
                lines.add('Object: ' + objectName + ' (' + describe.getLabel() + ')');
                lines.add('Field Name\tType\tReferences\tRelationship Name\tPicklist Values');
                lines.add('-------------------------------------------');
                
                List<String> fieldLines = new List<String>();
                for(Schema.SObjectField field : describe.fields.getMap().values()) {
                    Schema.DescribeFieldResult fieldDescribe = field.getDescribe();
                    String line = fieldDescribe.getName() + '\t' + fieldDescribe.getType().name();
                    
                    if(fieldDescribe.getType() == Schema.DisplayType.REFERENCE) {
                        List<String> refs = new List<String>();
                        for(Schema.SObjectType ref : fieldDescribe.getReferenceTo()) {
                            refs.add(ref.getDescribe().getName());
                        }
                        line += '\t' + String.join(refs, ',');
                        line += '\t' + fieldDescribe.getRelationshipName();
                        line += '\t'; // empty picklist values
                    } 
                    else if(fieldDescribe.getType() == Schema.DisplayType.PICKLIST || 
                           fieldDescribe.getType() == Schema.DisplayType.MULTIPICKLIST) {
                        line += '\t\t\t'; // empty refs and relationship
                        List<String> pickVals = new List<String>();
                        for(Schema.PicklistEntry entry : fieldDescribe.getPicklistValues()) {
                            if(entry.isActive()) {
                                pickVals.add(entry.getValue());
                            }
                        }
                        line += String.join(pickVals, ', ');
                    }
                    else {
                        line += '\t\t\t'; // empty refs, relationship and picklist
                    }
                    
                    fieldLines.add(line);
                }
                fieldLines.sort();
                lines.addAll(fieldLines);
                lines.add(''); // blank line between objects
            }
        }
        
        return String.join(lines, '\n');
    }
    
    private static Set<String> getObjectsToDescribe(String objectNamesStr) {
        Map<String, Schema.SObjectType> globalDescribe = Schema.getGlobalDescribe();
        Set<String> result = new Set<String>();
        
        if(String.isNotBlank(objectNamesStr)) {
            // Split and trim the requested objects
            List<String> requestedObjects = new List<String>();
            for(String obj : objectNamesStr.split(',')) {
                requestedObjects.add(obj.trim());
            }
            
            // For each requested object, try to find a matching key in a case-insensitive manner.
            for(String req : requestedObjects) {
                if(globalDescribe.containsKey(req)) {
                    result.add(req);
                } else {
                    for(String key : globalDescribe.keySet()) {
                        if(key.equalsIgnoreCase(req)) {
                            result.add(key);
                            break;
                        }
                    }
                }
            }
            return result;
        }
        return globalDescribe.keySet();
    }
    
    // INNER
    
    public class Input {
        @InvocableVariable(label='Scope' description='allObjects, objectDetails' required=true)
        public String scope;
        
        @InvocableVariable(label='Object API Names' description='Specific objects to investigate (if scope is specificObject or relationships)')
        public String objects;
    }
    
    public class Output {
        @InvocableVariable(label='Response as Text' description='Line-separated list of objects or field details')
        public String response;
        
        public Output(String response) {
            this.response = response;
        }
    }
}