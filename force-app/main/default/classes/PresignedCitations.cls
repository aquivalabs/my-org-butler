public with sharing class PresignedCitations {

    private String chunkDmo;
    private String directoryDmo;


    // CONSTRUCTOR

    public PresignedCitations(String chunkDmo) {
        this.chunkDmo = chunkDmo;
        this.directoryDmo = chunkDmo.replace('_chunk', '');
    }


    // PUBLIC

    public AiCopilot.GenAiCitationInput forDocuments(Set<String> documentIds) {
        List<String> quoted = new List<String>();
        for (String docId : documentIds) {
            quoted.add('\'' + String.escapeSingleQuotes(docId) + '\'');
        }

        String responseBody = DataCloudSql.query(
            'SELECT get_presigned_url(TABLE(' + directoryDmo + '), d.ResolvedFilePath__c, 180), d.ResolvedFilePath__c ' +
            'FROM "' + directoryDmo + '" d ' +
            'WHERE d.FilePath__c IN (' + String.join(quoted, ', ') + ')'
        );

        return toCitations(responseBody);
    }


    // PRIVATE

    private AiCopilot.GenAiCitationInput toCitations(String responseBody) {
        List<AiCopilot.GenAiSourceReference> result = new List<AiCopilot.GenAiSourceReference>();

        Map<String, Object> parsed = (Map<String, Object>) JSON.deserializeUntyped(responseBody);
        List<Object> rows = (List<Object>) parsed.get('data');

        if (rows == null) {
            return new AiCopilot.GenAiCitationInput(null, result);
        }

        for (Object row : rows) {
            List<Object> values = (List<Object>) row;
            String url = (String) values[0];
            String filePath = (String) values[1];
            String fileName = filePath.substringAfterLast('/');

            result.add(new AiCopilot.GenAiSourceReference(
                null,
                new List<AiCopilot.GenAiSourceContentInfo>{
                    new AiCopilot.GenAiSourceContentInfo('DataSource__c', chunkDmo, 'FilePath__c'),
                    new AiCopilot.GenAiSourceContentInfo('DataSourceObject__c', chunkDmo, directoryDmo),
                    new AiCopilot.GenAiSourceContentInfo('FilePath__c', directoryDmo, fileName)
                },
                new List<AiCopilot.GenAiSourceReferenceInfo>{
                    new AiCopilot.GenAiSourceReferenceInfo(url, fileName, directoryDmo)
                }
            ));
        }

        return new AiCopilot.GenAiCitationInput(null, result);
    }
}
