public virtual with sharing class DataLibrary {

    private static final Integer DEFAULT_TOP_K = 10;
    private static final Decimal DEFAULT_SIMILARITY_THRESHOLD = 0.4;
    private static final Integer MAX_CHUNKS = 1000;


    @TestVisible
    private static String mockedResult;


    // PUBLIC

    public String retrieve(String query, String chunkDmo, String searchIndex, Boolean chunksOnly) {
        if (Test.isRunningTest() && mockedResult != null) {
            return mockedResult;
        }

        if (String.isBlank(chunkDmo) || !Pattern.matches('[A-Za-z0-9_]+', chunkDmo)) {
            return '';
        }

        if (String.isBlank(searchIndex) || !Pattern.matches('[A-Za-z0-9_]+', searchIndex)) {
            return '';
        }

        String result = '';

        Set<String> documentIds = findRelevantDocumentIds(query, searchIndex, chunkDmo);

        if (!documentIds.isEmpty()) {
            ConnectApi.CdpQueryOutputV2 chunkRows = chunksOnly
                ? queryChunksFor(query, searchIndex, chunkDmo)
                : queryAllChunksOf(documentIds, chunkDmo);

            result = toJson(chunkRows, chunksOnly);
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


    // INNER

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
