@SuppressWarnings('PMD.ApexSuggestUsingNamedCred')
public virtual with sharing class DataLibrary {

    private static final Integer DEFAULT_TOP_K = 10;
    private static final Decimal DEFAULT_SIMILARITY_THRESHOLD = 0.4;
    private static final Integer MAX_CHUNKS = 1000;
    private static final String QUERY_SQL_ENDPOINT = '/services/data/v66.0/ssot/query-sql';


    @TestVisible
    private static String mockedResult;


    // PUBLIC

    public Result retrieve(String query, String chunkDmo, Boolean chunksOnly) {
        if (Test.isRunningTest() && mockedResult != null) {
            Result r = new Result();
            r.documents = mockedResult;
            return r;
        }

        if (String.isBlank(chunkDmo) || !Pattern.matches('[A-Za-z0-9_]+', chunkDmo)) {
            return new Result();
        }

        Result result = new Result();

        String searchIndex = chunkDmo.replace('_chunk', '_index');
        String directoryDmo = chunkDmo.replace('_chunk', '');
        Set<String> documentIds = findRelevantDocumentIds(query, searchIndex, chunkDmo);

        if (!documentIds.isEmpty()) {
            ConnectApi.CdpQueryOutputV2 chunkRows = chunksOnly
                ? queryChunksFor(query, searchIndex, chunkDmo)
                : queryAllChunksOf(documentIds, chunkDmo);

            result.documents = toJson(chunkRows, chunksOnly);
            result.citations = queryPresignedCitations(directoryDmo, chunkDmo, documentIds);
        }

        return result;
    }


    // PROTECTED

    @TestVisible
    protected virtual ConnectApi.CdpQueryOutputV2 queryCdp(String sql) {
        ConnectApi.CdpQueryInput input = new ConnectApi.CdpQueryInput();
        input.sql = sql;

        return ConnectApi.CdpQuery.queryANSISqlV2(input);
    }


    @TestVisible
    protected virtual String queryCdpRest(String sql) {
        HttpRequest request = new HttpRequest();
        request.setMethod('POST');
        request.setHeader('Authorization', 'Bearer ' + new SessionId().asString());
        request.setHeader('Content-Type', 'application/json');
        request.setEndpoint(Url.getOrgDomainURL().toExternalForm() + QUERY_SQL_ENDPOINT);
        request.setBody(JSON.serialize(new Map<String, String>{ 'sql' => sql }));

        HttpResponse response = new Http().send(request);

        return response.getBody();
    }


    // PRIVATE

    private Set<String> findRelevantDocumentIds(String query, String searchIndex, String chunkDmo) {
        Set<String> result = new Set<String>();

        String escapedQuery = String.escapeSingleQuotes(query);
        String topK = String.valueOf(DEFAULT_TOP_K);
        String threshold = String.valueOf(DEFAULT_SIMILARITY_THRESHOLD);

        ConnectApi.CdpQueryOutputV2 queryResult = queryCdp(
            'SELECT DISTINCT c.SourceRecordId__c ' +
            'FROM hybrid_search(TABLE(' + searchIndex + '), \'' + escapedQuery + '\', \'\', ' + topK + ') h ' +
            'JOIN ' + chunkDmo + ' c ON h.SourceRecordId__c = c.RecordId__c ' +
            'WHERE h.hybrid_score__c >= ' + threshold + ' ' +
            'LIMIT ' + topK
        );

        if (queryResult != null && queryResult.data != null) {
            for (ConnectApi.CdpQueryV2Row row : queryResult.data) {
                String docId = rowValue(row, 0);

                if (String.isNotBlank(docId)) {
                    result.add(docId);
                }
            }
        }

        return result;
    }


    private ConnectApi.CdpQueryOutputV2 queryChunksFor(String query, String searchIndex, String chunkDmo) {
        String escapedQuery = String.escapeSingleQuotes(query);
        String topK = String.valueOf(DEFAULT_TOP_K);
        String threshold = String.valueOf(DEFAULT_SIMILARITY_THRESHOLD);

        return queryCdp(
            'SELECT c.SourceRecordId__c, c.Chunk__c ' +
            'FROM hybrid_search(TABLE(' + searchIndex + '), \'' + escapedQuery + '\', \'\', ' + topK + ') h ' +
            'JOIN ' + chunkDmo + ' c ON h.SourceRecordId__c = c.RecordId__c ' +
            'WHERE h.hybrid_score__c >= ' + threshold + ' ' +
            'LIMIT ' + topK
        );
    }


    private ConnectApi.CdpQueryOutputV2 queryAllChunksOf(Set<String> documentIds, String chunkDmo) {
        return queryCdp(
            'SELECT SourceRecordId__c, Chunk__c FROM ' + chunkDmo + ' ' +
            'WHERE SourceRecordId__c IN (' + toSqlList(documentIds) + ') ' +
            'ORDER BY SourceRecordId__c, ChunkSequenceNumber__c ' +
            'LIMIT ' + String.valueOf(MAX_CHUNKS)
        );
    }


    private String toSqlList(Set<String> values) {
        List<String> result = new List<String>();

        for (String value : values) {
            result.add('\'' + String.escapeSingleQuotes(value) + '\'');
        }

        return String.join(result, ', ');
    }


    private String toJson(ConnectApi.CdpQueryOutputV2 queryResult, Boolean chunksOnly) {
        Map<String, Document> bySourceId = new Map<String, Document>();

        if (queryResult != null && queryResult.data != null) {
            for (ConnectApi.CdpQueryV2Row row : queryResult.data) {
                String sourceRecordId = rowValue(row, 0);
                String content = rowValue(row, 1);

                if (String.isBlank(content)) {
                    continue;
                }

                if (!bySourceId.containsKey(sourceRecordId)) {
                    String fileName = sourceRecordId.contains('/')
                        ? sourceRecordId.substringAfter('/')
                        : sourceRecordId;

                    bySourceId.put(sourceRecordId, new Document(fileName, sourceRecordId, chunksOnly));
                }

                bySourceId.get(sourceRecordId).chunks.add(content);
            }
        }

        List<Document> result = bySourceId.values();
        for (Document doc : result) {
            doc.content = String.join(doc.chunks, '\n');
        }

        return JSON.serialize(result);
    }


    private String rowValue(ConnectApi.CdpQueryV2Row row, Integer idx) {
        String result = null;

        if (idx < row.rowData.size() && row.rowData[idx] != null) {
            result = String.valueOf(row.rowData[idx]);
        }

        return result;
    }


    private AiCopilot.GenAiCitationInput queryPresignedCitations(String directoryDmo, String chunkDmo, Set<String> documentIds) {
        List<AiCopilot.GenAiSourceReference> sourceReferences = new List<AiCopilot.GenAiSourceReference>();

        List<String> conditions = new List<String>();
        for (String docId : documentIds) {
            conditions.add('d.ResolvedFilePath__c LIKE \'%' + String.escapeSingleQuotes(docId) + '\'');
        }

        String responseBody = queryCdpRest(
            'SELECT get_presigned_url(TABLE(' + directoryDmo + '), d.ResolvedFilePath__c, 180), d.ResolvedFilePath__c ' +
            'FROM "' + directoryDmo + '" d ' +
            'WHERE ' + String.join(conditions, ' OR ')
        );

        Map<String, Object> parsed = (Map<String, Object>) JSON.deserializeUntyped(responseBody);
        List<Object> rows = (List<Object>) parsed.get('data');

        if (rows != null) {
            for (Object row : rows) {
                List<Object> values = (List<Object>) row;
                String url = (String) values[0];
                String filePath = (String) values[1];

                if (String.isNotBlank(filePath) && String.isNotBlank(url)) {
                    String fileName = filePath.substringAfterLast('/');

                    sourceReferences.add(new AiCopilot.GenAiSourceReference(
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
            }
        }

        return sourceReferences.isEmpty() ? null : new AiCopilot.GenAiCitationInput(null, sourceReferences);
    }


    // INNER

    public class Result {
        public String documents = '';
        public AiCopilot.GenAiCitationInput citations;
    }


    private class Document {
        private String fileName;
        private String sourceId;
        private String type;
        private String content;
        private transient List<String> chunks = new List<String>();

        private Document(String fileName, String sourceRecordId, Boolean chunksOnly) {
            this.fileName = fileName;
            this.sourceId = sourceRecordId.contains('/')
                ? sourceRecordId.substringBefore('/')
                : sourceRecordId;
            this.type = chunksOnly ? 'chunk' : 'full_document';
        }
    }
}
