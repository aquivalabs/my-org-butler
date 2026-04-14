@IsTest
private class DataLibrary_Test {

    private static final String CHUNK_DMO = 'TestChunk_chunk__dll';
    private static MockDataLibrary mock = new MockDataLibrary();


    @IsTest
    private static void returnsEmptyForNoMatches() {

        // Setup
        mock.whenQueryContains('hybrid_search', createQueryResult(new List<List<Object>>()));


        // Exercise
        String result = mock.retrieve('test query', CHUNK_DMO, false);


        // Verify
        Assert.areEqual('', result);
    }


    @IsTest
    private static void returnsJsonWithFileNameAndContent() {

        // Setup
        mock.whenQueryContains('hybrid_search', createQueryResult(new List<List<Object>>{
            new List<Object>{ 'doc1' }
        }));

        mock.whenQueryContains('Chunk__c', createQueryResult(new List<List<Object>>{
            new List<Object>{ '1JDRt000001/policy.pdf', 'First chunk' },
            new List<Object>{ '1JDRt000001/policy.pdf', 'Second chunk' }
        }));


        // Exercise
        String result = mock.retrieve('discount policy', CHUNK_DMO, false);


        // Verify
        List<Object> documents = (List<Object>) JSON.deserializeUntyped(result);
        Assert.areEqual(1, documents.size());

        Map<String, Object> doc = (Map<String, Object>) documents[0];
        Assert.areEqual('policy.pdf', doc.get('fileName'));
        Assert.areEqual('1JDRt000001', doc.get('sourceId'));
        Assert.areEqual('full_document', doc.get('type'));
        Assert.isTrue(((String) doc.get('content')).contains('First chunk'));
        Assert.isTrue(((String) doc.get('content')).contains('Second chunk'));
    }


    @IsTest
    private static void groupsChunksByDocument() {

        // Setup
        mock.whenQueryContains('hybrid_search', createQueryResult(new List<List<Object>>{
            new List<Object>{ 'doc1' },
            new List<Object>{ 'doc2' }
        }));

        mock.whenQueryContains('Chunk__c', createQueryResult(new List<List<Object>>{
            new List<Object>{ '1JDRt000001/policy.pdf', 'Policy content' },
            new List<Object>{ '1JDRt000002/handbook.pdf', 'Handbook content' }
        }));


        // Exercise
        String result = mock.retrieve('company docs', CHUNK_DMO, false);


        // Verify
        List<Object> documents = (List<Object>) JSON.deserializeUntyped(result);
        Assert.areEqual(2, documents.size());
    }


    @IsTest
    private static void returnsEmptyForNullResult() {

        // Setup
        ConnectApi.CdpQueryOutputV2 queryResult = new ConnectApi.CdpQueryOutputV2();
        queryResult.data = null;
        mock.whenQueryContains('hybrid_search', queryResult);


        // Exercise
        String result = mock.retrieve('test query', CHUNK_DMO, false);


        // Verify
        Assert.areEqual('', result);
    }


    @IsTest
    private static void skipsBlankDocumentIds() {

        // Setup
        mock.whenQueryContains('hybrid_search', createQueryResult(new List<List<Object>>{
            new List<Object>{ 'doc1' },
            new List<Object>{ '' },
            new List<Object>{ null }
        }));

        mock.whenQueryContains('Chunk__c', createQueryResult(new List<List<Object>>{
            new List<Object>{ '1JDRt000001/policy.pdf', 'Valid content' }
        }));


        // Exercise
        String result = mock.retrieve('test query', CHUNK_DMO, false);


        // Verify
        Assert.isTrue(result.contains('Valid content'));
    }


    @IsTest
    private static void derivesSearchIndex() {

        // Setup
        mock.whenQueryContains('hybrid_search', createQueryResult(new List<List<Object>>()));


        // Exercise
        mock.retrieve('test', 'ADL_CpdT_MyOrgButle_chunk__dll', false);


        // Verify
        Assert.isTrue(mock.lastQuery().contains('ADL_CpdT_MyOrgButle_index__dll'));
    }


    @IsTest
    private static void usesDefaultSimilarityThreshold() {

        // Setup
        mock.whenQueryContains('hybrid_search', createQueryResult(new List<List<Object>>()));


        // Exercise
        mock.retrieve('test', CHUNK_DMO, false);


        // Verify
        Assert.isTrue(mock.lastQuery().contains('0.4'));
    }


    @IsTest
    private static void escapesApostrophesInQuery() {

        // Setup
        mock.whenQueryContains('hybrid_search', createQueryResult(new List<List<Object>>()));


        // Exercise
        mock.retrieve('colleague\'s non-working day', CHUNK_DMO, false);


        // Verify
        Assert.isTrue(mock.lastQuery().contains('colleague\\\'s non-working day'));
    }


    // HELPER

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


    private class MockDataLibrary extends DataLibrary {
        private List<String> executedQueries = new List<String>();
        private Map<String, ConnectApi.CdpQueryOutputV2> responses = new Map<String, ConnectApi.CdpQueryOutputV2>();

        public void whenQueryContains(String pattern, ConnectApi.CdpQueryOutputV2 result) {
            responses.put(pattern, result);
        }

        public String lastQuery() {
            return executedQueries.isEmpty() ? null : executedQueries[executedQueries.size() - 1];
        }

        protected override ConnectApi.CdpQueryOutputV2 queryCdp(String sql) {
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
