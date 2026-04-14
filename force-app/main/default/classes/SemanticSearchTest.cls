@IsTest
private class SemanticSearchTest {

    private static MockCdpQuery mockCdpQuery = new MockCdpQuery();


    @IsTest
    private static void returnsEmptyResultWhenNoDocumentsFound() {

        // Setup
        mockCdpQuery.whenQueryContains('hybrid_search', createQueryResult(new List<List<Object>>()));


        // Exercise
        String result = search('test query');


        // Verify
        Assert.areEqual('', result);
    }


    @IsTest
    private static void returnsFormattedDocumentContent() {

        // Setup
        mockCdpQuery.whenQueryContains('hybrid_search', createQueryResult(new List<List<Object>>{
            new List<Object>{ 'doc1' },
            new List<Object>{ 'doc2' }
        }));

        mockCdpQuery.whenQueryContains('Chunk__c', createQueryResult(new List<List<Object>>{
            new List<Object>{ 'doc1', 'Content from document 1' },
            new List<Object>{ 'doc2', 'Content from document 2' }
        }));


        // Exercise
        String result = search('maternity policy');


        // Verify
        Assert.isTrue(result.contains('Content from document 1'));
        Assert.isTrue(result.contains('Content from document 2'));
    }


    @IsTest
    private static void handlesNullDataInHybridSearchResult() {

        // Setup
        ConnectApi.CdpQueryOutputV2 queryResult = new ConnectApi.CdpQueryOutputV2();
        queryResult.data = null;
        mockCdpQuery.whenQueryContains('hybrid_search', queryResult);


        // Exercise
        String result = search('test query');


        // Verify
        Assert.areEqual('', result);
    }


    @IsTest
    private static void filtersOutBlankDocumentIds() {

        // Setup
        mockCdpQuery.whenQueryContains('hybrid_search', createQueryResult(new List<List<Object>>{
            new List<Object>{ 'doc1' },
            new List<Object>{ '' },
            new List<Object>{ null }
        }));

        mockCdpQuery.whenQueryContains('Chunk__c', createQueryResult(new List<List<Object>>{
            new List<Object>{ 'doc1', 'Valid content' }
        }));


        // Exercise
        String result = search('test query');


        // Verify
        Assert.isTrue(result.contains('Valid content'));
    }


    @IsTest
    private static void derivesSearchIndexFromChunkDmo() {

        // Setup
        mockCdpQuery.whenQueryContains('hybrid_search', createQueryResult(new List<List<Object>>()));


        // Exercise
        SemanticSearch semanticSearch = new SemanticSearch();
        semanticSearch.cdpQuery = mockCdpQuery;
        semanticSearch.execute('test', 'ADL_MyOrgButlerLibr_chunk__dlm');


        // Verify
        Assert.isTrue(mockCdpQuery.lastQuery().contains('ADL_MyOrgButlerLibr_index__dlm'));
    }


    @IsTest
    private static void usesDefaultSimilarityThreshold() {

        // Setup
        mockCdpQuery.whenQueryContains('hybrid_search', createQueryResult(new List<List<Object>>()));


        // Exercise
        search('test');


        // Verify
        Assert.isTrue(mockCdpQuery.lastQuery().contains('0.4'));
    }


    @IsTest
    private static void stripsApostrophesFromQuery() {

        // Setup
        mockCdpQuery.whenQueryContains('hybrid_search', createQueryResult(new List<List<Object>>()));


        // Exercise
        search('colleague\'s non-working day');


        // Verify
        Assert.isTrue(mockCdpQuery.lastQuery().contains('colleagues non-working day'));
    }


    // HELPER

    private static String search(String query) {
        SemanticSearch semanticSearch = new SemanticSearch();
        semanticSearch.cdpQuery = mockCdpQuery;
        return semanticSearch.execute(query, 'TestChunk_chunk__dlm');
    }


    private static ConnectApi.CdpQueryOutputV2 createQueryResult(List<List<Object>> rows) {
        ConnectApi.CdpQueryOutputV2 result = new ConnectApi.CdpQueryOutputV2();
        result.data = new List<ConnectApi.CdpQueryV2Row>();

        for (List<Object> rowData : rows) {
            ConnectApi.CdpQueryV2Row row = new ConnectApi.CdpQueryV2Row();
            row.rowData = rowData;
            result.data.add(row);
        }

        return result;
    }


    // MOCK

    private class MockCdpQuery extends CdpQuery {
        private List<String> executedQueries = new List<String>();
        private Map<String, ConnectApi.CdpQueryOutputV2> responses = new Map<String, ConnectApi.CdpQueryOutputV2>();

        public void whenQueryContains(String pattern, ConnectApi.CdpQueryOutputV2 result) {
            responses.put(pattern, result);
        }

        public String lastQuery() {
            return executedQueries.isEmpty() ? null : executedQueries[executedQueries.size() - 1];
        }

        public override ConnectApi.CdpQueryOutputV2 query(String sql) {
            executedQueries.add(sql);

            for (String pattern : responses.keySet()) {
                if (sql.containsIgnoreCase(pattern)) {
                    return responses.get(pattern);
                }
            }

            return null;
        }
    }
}