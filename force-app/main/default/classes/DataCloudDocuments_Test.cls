@IsTest
private class DataCloudDocuments_Test {

    private static MockDataCloudDocuments mock = new MockDataCloudDocuments();


    @IsTest
    private static void returnsEmptyResultWhenNoDocumentsFound() {

        // Setup
        mock.whenQueryContains('hybrid_search', createQueryResult(new List<List<Object>>()));


        // Exercise
        String result = retrieve('test query');


        // Verify
        Assert.areEqual('', result);
    }


    @IsTest
    private static void returnsFormattedDocumentContent() {

        // Setup
        mock.whenQueryContains('hybrid_search', createQueryResult(new List<List<Object>>{
            new List<Object>{ 'doc1' },
            new List<Object>{ 'doc2' }
        }));

        mock.whenQueryContains('Chunk__c', createQueryResult(new List<List<Object>>{
            new List<Object>{ 'doc1', 'Content from document 1' },
            new List<Object>{ 'doc2', 'Content from document 2' }
        }));


        // Exercise
        String result = retrieve('maternity policy');


        // Verify
        Assert.isTrue(result.contains('Content from document 1'));
        Assert.isTrue(result.contains('Content from document 2'));
    }


    @IsTest
    private static void handlesNullDataInHybridSearchResult() {

        // Setup
        ConnectApi.CdpQueryOutputV2 queryResult = new ConnectApi.CdpQueryOutputV2();
        queryResult.data = null;
        mock.whenQueryContains('hybrid_search', queryResult);


        // Exercise
        String result = retrieve('test query');


        // Verify
        Assert.areEqual('', result);
    }


    @IsTest
    private static void filtersOutBlankDocumentIds() {

        // Setup
        mock.whenQueryContains('hybrid_search', createQueryResult(new List<List<Object>>{
            new List<Object>{ 'doc1' },
            new List<Object>{ '' },
            new List<Object>{ null }
        }));

        mock.whenQueryContains('Chunk__c', createQueryResult(new List<List<Object>>{
            new List<Object>{ 'doc1', 'Valid content' }
        }));


        // Exercise
        String result = retrieve('test query');


        // Verify
        Assert.isTrue(result.contains('Valid content'));
    }


    @IsTest
    private static void derivesSearchIndexFromChunkDmo() {

        // Setup
        mock.whenQueryContains('hybrid_search', createQueryResult(new List<List<Object>>()));


        // Exercise
        mock.retrieve('test', 'ADL_MyOrgButlerLibr_chunk__dlm');


        // Verify
        Assert.isTrue(mock.lastQuery().contains('ADL_MyOrgButlerLibr_index__dlm'));
    }


    @IsTest
    private static void usesDefaultSimilarityThreshold() {

        // Setup
        mock.whenQueryContains('hybrid_search', createQueryResult(new List<List<Object>>()));


        // Exercise
        retrieve('test');


        // Verify
        Assert.isTrue(mock.lastQuery().contains('0.4'));
    }


    @IsTest
    private static void escapesApostrophesInQuery() {

        // Setup
        mock.whenQueryContains('hybrid_search', createQueryResult(new List<List<Object>>()));


        // Exercise
        retrieve('colleague\'s non-working day');


        // Verify
        Assert.isTrue(mock.lastQuery().contains('colleague\\\'s non-working day'));
    }


    // HELPER

    private static String retrieve(String query) {
        return mock.retrieve(query, 'TestChunk_chunk__dlm');
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


    private class MockDataCloudDocuments extends DataCloudDocuments {
        private List<String> executedQueries = new List<String>();
        private Map<String, ConnectApi.CdpQueryOutputV2> responses = new Map<String, ConnectApi.CdpQueryOutputV2>();

        public void whenQueryContains(String pattern, ConnectApi.CdpQueryOutputV2 result) {
            responses.put(pattern, result);
        }

        public String lastQuery() {
            return executedQueries.isEmpty() ? null : executedQueries[executedQueries.size() - 1];
        }

        protected override ConnectApi.CdpQueryOutputV2 query(String sql) {
            ConnectApi.CdpQueryOutputV2 result = null;

            executedQueries.add(sql);

            for (String pattern : responses.keySet()) {
                if (sql.containsIgnoreCase(pattern)) {
                    result = responses.get(pattern);
                    break;
                }
            }

            return result;
        }
    }
}
