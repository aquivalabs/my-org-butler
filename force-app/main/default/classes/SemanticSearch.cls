public with sharing class SemanticSearch {

    private static final Integer DEFAULT_TOP_K = 10;
    private static final Decimal DEFAULT_SIMILARITY_THRESHOLD = 0.4;
    private static final Integer MAX_CHUNKS = 1000;

    @TestVisible
    private CdpQuery cdpQuery = new CdpQuery();


    // PUBLIC

    public String execute(String query, String chunkDmo) {
        String result = '';

        if (String.isNotBlank(chunkDmo)) {
            String searchIndex = deriveSearchIndex(chunkDmo);
            Set<String> documentIds = findRelevantDocuments(query, searchIndex, chunkDmo);

            if (!documentIds.isEmpty()) {
                result = formatAsText(fetchChunks(documentIds, chunkDmo));
            }
        }

        return result;
    }


    // PRIVATE


    private String deriveSearchIndex(String chunkDmo) {
        return chunkDmo.replace('_chunk__dlm', '_index__dlm');
    }


    private Set<String> findRelevantDocuments(String query, String searchIndex, String chunkDmo) {
        String sql = buildHybridSearchSql(query, searchIndex, chunkDmo);
        return extractDocumentIds(cdpQuery.query(sql));
    }


    private String buildHybridSearchSql(String query, String searchIndex, String chunkDmo) {
        String escapedQuery = String.escapeSingleQuotes(query);
        String threshold = String.valueOf(DEFAULT_SIMILARITY_THRESHOLD);
        String topK = String.valueOf(DEFAULT_TOP_K);

        return String.format(
            'SELECT DISTINCT c.SourceRecordId__c ' +
            'FROM hybrid_search(TABLE({0}), \'\'{1}\'\', \'\'\'\', {2}) h ' +
            'JOIN {3} c ON h.SourceRecordId__c = c.RecordId__c ' +
            'WHERE h.hybrid_score__c >= {4} ' +
            'LIMIT {5}',
            new List<String>{ searchIndex, escapedQuery, topK, chunkDmo, threshold, topK }
        );
    }


    private Set<String> extractDocumentIds(ConnectApi.CdpQueryOutputV2 queryResult) {
        Set<String> result = new Set<String>();

        if (queryResult != null && queryResult.data != null) {
            for (ConnectApi.CdpQueryV2Row row : queryResult.data) {
                String docId = getString(row.rowData, 0);
                if (String.isNotBlank(docId)) {
                    result.add(docId);
                }
            }
        }

        return result;
    }


    private List<Chunk> fetchChunks(Set<String> documentIds, String chunkDmo) {
        String sql = buildDocumentQuerySql(documentIds, chunkDmo);
        return parseChunks(cdpQuery.query(sql));
    }


    private String buildDocumentQuerySql(Set<String> documentIds, String chunkDmo) {
        List<String> quotedIds = new List<String>();
        for (String docId : documentIds) {
            quotedIds.add('\'' + String.escapeSingleQuotes(docId) + '\'');
        }

        return 'SELECT SourceRecordId__c, Chunk__c FROM ' + chunkDmo + ' ' +
            'WHERE SourceRecordId__c IN (' + String.join(quotedIds, ', ') + ') ' +
            'ORDER BY SourceRecordId__c, ChunkSequenceNumber__c ' +
            'LIMIT ' + String.valueOf(MAX_CHUNKS);
    }


    private List<Chunk> parseChunks(ConnectApi.CdpQueryOutputV2 queryResult) {
        List<Chunk> result = new List<Chunk>();

        if (queryResult != null && queryResult.data != null) {
            for (ConnectApi.CdpQueryV2Row row : queryResult.data) {
                String sourceId = getString(row.rowData, 0);
                String content = getString(row.rowData, 1);

                if (String.isNotBlank(content)) {
                    Chunk chunk = new Chunk();
                    chunk.sourceId = sourceId;
                    chunk.content = content;
                    result.add(chunk);
                }
            }
        }

        return result;
    }


    private String formatAsText(List<Chunk> chunks) {
        List<String> entries = new List<String>();

        for (Chunk chunk : chunks) {
            entries.add(chunk.content);
        }

        return String.join(entries, '\n###\n');
    }


    private String getString(List<Object> data, Integer idx) {
        String result = null;

        if (idx < data.size() && data[idx] != null) {
            result = String.valueOf(data[idx]);
        }

        return result;
    }


    // INNER

    private class Chunk {
        private String sourceId;
        private String content;
    }
}