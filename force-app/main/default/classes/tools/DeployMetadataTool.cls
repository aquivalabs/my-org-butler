public with sharing class DeployMetadataTool extends MyOrgButler.Tool {
    
    public override String execute(String paramsJson) {
        List<File> files = new List<File>();
        
        for(JSONParse parser : new JsonParse(paramsJson).get('files').asList()) {
            File file = new File();
            file.name = parser.get('fileName').getStringValue();
            file.content = parser.get('fileContent').getStringValue();
            
            files.add(file);
        }
        return JSON.serialize(execute(files));
    }

    // PRIVATE

    public MetadataService.DeployResult execute(List<File> files) {
        MetadataService.DeployOptions options = new MetadataService.DeployOptions();
        options.allowMissingFiles = false;
        options.autoUpdatePackage = true;
        options.checkOnly = false;
        options.ignoreWarnings = true;
        options.performRetrieve = false;
        options.purgeOnDelete = false;
        options.rollbackOnError = true;
        options.testLevel = 'NoTestRun';
        options.singlePackage = true;	

        MetadataService.MetadataPort service = new MetadataService.MetadataPort();
		service.SessionHeader = new MetadataService.SessionHeader_element();
		service.SessionHeader.sessionId = new SessionId().asString();

        MetadataService.AsyncResult asyncResult = service.deploy(zip(files), options);
        MetadataService.DeployResult result;
        do {
            MyOrgButler.sleep(3000);
            result = service.checkDeployStatus(asyncResult.id, true);
        }
        while(result.done == false);
        return result;
    }

    // PRIVATE

    private static String zip(List<File> files) {
        Zippex zip = new Zippex();

        for (File file : files) {
            zip.addFile(file.name, Blob.valueOf(file.content), null);
        }

        return EncodingUtil.base64Encode(zip.getZipArchive());
    }


    // INNER

    public class File {
        public String name;
        public String content;
    }
}