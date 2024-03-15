// PMD False Positive: Calling regular Salesforce APIs can be done with Session Id
@SuppressWarnings('PMD.ApexSuggestUsingNamedCred') // AvoidUnauthorizedGetSessionIdInApex
public with sharing class DeployMetadataTool implements MyOrgButler.Tool {

    @InvocableMethod(label='Deploy Metadata using ZIP' 
                     description='Deploys Metadata using an in-memory ZIP file created from provided files' 
                     category='EinsteinCopilot' 
                     callout=true)
    public static List<Output> execute(List<File> files) {
        HttpRequest request = new HttpRequest();
        request.setHeader('Authorization', 'Bearer ' + new SessionId().asString());
        request.setEndpoint(Url.getOrgDomainURL().toExternalForm() + '/services/data/v60.0/metadata/deployRequest');
        request.setHeader('Accept', '*/*');
        request.setHeader('Connection', 'Keep-Alive');
        request.setHeader('Content-Type', 'multipart/form-data');
    
        String jsonPayload = '{' +
            '"deployOptions" : {' +
            '    "allowMissingFiles" : true,' +
            '    "autoUpdatePackage" : false,' +
            '    "checkOnly" : false,' +
            '    "ignoreWarnings" : false,' +
            '    "performRetrieve" : false,' +
            '    "purgeOnDelete" : false,' +
            '    "rollbackOnError" : true,' +
            '    "runTests" : null,' +
            '    "singlePackage" : false,' +
            '    "testLevel" : "NoTestRun"' +
            '}' +
        '}';        
        String boundary = '----Boundary-' + String.valueOf(Datetime.now().getTime());
        request.setHeader('Content-Type', 'multipart/form-data; boundary=' + boundary);
        
        String body = '';
        
        // JSON Payload
        body += '--' + boundary + '\r\n';
        body += 'Content-Disposition: form-data; name="entity_content"\r\n';
        body += 'Content-Type: application/json\r\n\r\n';
        body += jsonPayload + '\r\n';
        
        // ZIP File
        body += '--' + boundary + '\r\n';
        body += 'Content-Disposition: form-data; name="file"; filename="unpackaged.zip"\r\n';
        body += 'Content-Type: application/zip\r\n\r\n';
        body += EncodingUtil.base64Encode(zip(files)) + '\r\n';
        
        // Closing boundary
        body += '--' + boundary + '--';
        
        //request.setHeader('Content-Type', 'multipart/form-data; boundary=' + boundary);
        request.setBodyAsBlob(Blob.valueof(body));

        HttpResponse response = new Http().send(request);
        Output result = new Output();
        if (response.getStatusCode() == 200) {
            result.deploymentStatus = 'Success';
        } else {
            result.deploymentStatus = 'Failed: ' + response.getStatus();
        }

        return new List<Output>{ result };
    }

    public String execute(String jsonParameter) {
        JsonReader reader = new JsonReader(jsonParameter);
        
        List<File> files = new List<File>();
        List<Map<String, Object>> filesArray = (List<Map<String, Object>>) reader.read('files');
        
        for(Map<String, Object> properties : filesArray) {
            File file = new File();
            file.name = (String) properties.get('fileName');
            file.content = (String) properties.get('fileContent');
            
            files.add(file);
        }
        
        List<Output> outputs = execute(files);
        return outputs.isEmpty() ? '{}' : JSON.serialize(outputs[0]);
    }

    // PRIVATE

    private static Blob zip(List<File> files) {
        Zippex zip = new Zippex();

        for (File file : files) {
            zip.addFile(file.name, Blob.valueOf(file.content), null);
        }

        return zip.getZipArchive();
    }

    // INNER

    public class File {
        @InvocableVariable(required = true)
        public String name;

        @InvocableVariable(required = true)
        public String content;
    }

    public class Output {
        @InvocableVariable(required = true)
        public String deploymentStatus;
    }
}