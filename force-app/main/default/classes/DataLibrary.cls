public virtual with sharing class DataLibrary {

    private static final Integer DEFAULT_TOP_K = 10;
    private static final Decimal DEFAULT_SIMILARITY_THRESHOLD = 0.4;
    private static final Integer MAX_CHUNKS = 1000;


    @TestVisible
    private static String mockedResult;


    // PUBLIC

    public virtual Result retrieve(String query, String chunkDmo, Boolean chunksOnly) {
        if (Test.isRunningTest() && mockedResult != null) {
            Result r = new Result();
            r.documents = mockedResult;
            return r;
        }

        if (String.isBlank(chunkDmo) || !Pattern.matches('[A-Za-z0-9_]+', chunkDmo)) {
            return new Result();
        }

        Result result = new Result();

        try {
            String searchIndex = chunkDmo.replace('_chunk', '_index');
            Set<String> documentIds = findRelevantDocumentIds(query, searchIndex, chunkDmo);

            if (!documentIds.isEmpty()) {
                QueryResult chunkRows = chunksOnly
                    ? queryChunksFor(query, searchIndex, chunkDmo)
                    : queryAllChunksOf(documentIds, chunkDmo);

                result.documents = toJson(chunkRows, chunksOnly);
                result.citations = new PresignedCitations(chunkDmo).forDocuments(documentIds);
            }
        }
        catch (Exception error) {
            System.debug(LoggingLevel.ERROR, 'DataLibrary: ' + error.getMessage());
        }

        return result;
    }


    // PROTECTED

    @TestVisible
    protected virtual QueryResult queryCdp(String sql) {
        Map<String, Object> parsed = (Map<String, Object>) JSON.deserializeUntyped(DataCloudSql.query(sql));
        List<Object> rows = (List<Object>) parsed.get('data');

        QueryResult result = new QueryResult();
        result.data = new List<QueryRow>();

        if (rows != null) {
            for (Object row : rows) {
                QueryRow qr = new QueryRow();
                qr.rowData = (List<Object>) row;
                result.data.add(qr);
            }
        }

        return result;
    }


    private Set<String> findRelevantDocumentIds(String query, String searchIndex, String chunkDmo) {
        Set<String> result = new Set<String>();

        String escapedQuery = String.escapeSingleQuotes(query);
        String topK = String.valueOf(DEFAULT_TOP_K);
        String threshold = String.valueOf(DEFAULT_SIMILARITY_THRESHOLD);

        QueryResult queryResult = queryCdp(
            'SELECT DISTINCT c.SourceRecordId__c ' +
            'FROM hybrid_search(TABLE(' + searchIndex + '), \'' + escapedQuery + '\', \'\', ' + topK + ') h ' +
            'JOIN ' + chunkDmo + ' c ON h.SourceRecordId__c = c.RecordId__c ' +
            'WHERE h.hybrid_score__c >= ' + threshold + ' ' +
            'LIMIT ' + topK
        );

        if (queryResult != null && queryResult.data != null) {
            for (QueryRow row : queryResult.data) {
                String docId = rowValue(row, 0);

                if (String.isNotBlank(docId)) {
                    result.add(docId);
                }
            }
        }

        return result;
    }


    private QueryResult queryChunksFor(String query, String searchIndex, String chunkDmo) {
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


    private QueryResult queryAllChunksOf(Set<String> documentIds, String chunkDmo) {
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


    // PMD False Positives:
    // - sourceRecordId comes from Data Cloud SourceRecordId__c, a required key field that is always populated
    @SuppressWarnings('PMD.ApexNullPointerException')
    private String toJson(QueryResult queryResult, Boolean chunksOnly) {
        Map<String, Document> bySourceId = new Map<String, Document>();

        if (queryResult != null && queryResult.data != null) {
            for (QueryRow row : queryResult.data) {
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


    private String rowValue(QueryRow row, Integer idx) {
        String result = null;

        if (idx < row.rowData.size() && row.rowData[idx] != null) {
            result = String.valueOf(row.rowData[idx]);
        }

        return result;
    }


    // INNER

    public class Result {
        public String documents = '';
        public AiCopilot.GenAiCitationInput citations;
    }


    @TestVisible
    class QueryResult {
        @TestVisible List<QueryRow> data;
    }


    @TestVisible
    class QueryRow {
        @TestVisible List<Object> rowData;
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
