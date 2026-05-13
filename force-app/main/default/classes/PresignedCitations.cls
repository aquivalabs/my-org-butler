public with sharing class PresignedCitations {

    private String directoryDmo;


    // CONSTRUCTOR

    public PresignedCitations(String chunkDmo) {
        this.directoryDmo = chunkDmo.replace('_chunk', '');
    }


    // PUBLIC

    public AiCopilot.GenAiCitationOutput forDocuments(Set<String> documentIds) {
        List<String> quoted = new List<String>();
        for (String docId : documentIds) {
            quoted.add('\'' + String.escapeSingleQuotes(docId) + '\'');
        }

        String responseBody = DataCloudSql.query(
            'SELECT get_presigned_url(TABLE(' + directoryDmo + '), d.ResolvedFilePath__c, 180), d.ResolvedFilePath__c ' +
            'FROM "' + directoryDmo + '" d ' +
            'WHERE d.FilePath__c IN (' + String.join(quoted, ', ') + ')'
        );

        return toCitations(extract(responseBody));
    }


    // PRIVATE

    @TestVisible
    private List<Citation> extract(String responseBody) {
        List<Citation> result = new List<Citation>();

        Map<String, Object> parsed = (Map<String, Object>) JSON.deserializeUntyped(responseBody);
        List<Object> rows = (List<Object>) parsed.get('data');

        if (rows == null) {
            return result;
        }

        for (Object row : rows) {
            List<Object> values = (List<Object>) row;
            result.add(new Citation(
                (String) values[0],
                ((String) values[1]).substringAfterLast('/')
            ));
        }

        return result;
    }


    // Note: GenAiCitationOutput has package-private fields with no accessible
    //   setter or list-arg constructor, so JSON.deserialize is the only way to
    //   populate it from external Apex. Also, the published reference says
    //   GenAiCitedReference.metadata is a single GenAiCitedReferenceInfo, but the
    //   runtime requires a List — see issue #60.
    private AiCopilot.GenAiCitationOutput toCitations(List<Citation> citations) {
        List<Map<String, Object>> references = new List<Map<String, Object>>();

        for (Citation citation : citations) {
            references.add(new Map<String, Object>{
                'metadata' => new List<Map<String, Object>>{
                    new Map<String, Object>{
                        'link' => citation.url,
                        'source_object_record_id' => citation.fileName,
                        'source_object_api_name' => directoryDmo,
                        'label' => citation.fileName
                    }
                }
            });
        }

        String payload = JSON.serialize(new Map<String, Object>{
            'references' => references
        });

        AiCopilot.GenAiCitationOutput result = (AiCopilot.GenAiCitationOutput)
            JSON.deserialize(payload, AiCopilot.GenAiCitationOutput.class);

        return result;
    }


    // INNER

    @TestVisible
    public class Citation {
        public String url;
        public String fileName;

        public Citation(String url, String fileName) {
            this.url = url;
            this.fileName = fileName;
        }
    }
}
