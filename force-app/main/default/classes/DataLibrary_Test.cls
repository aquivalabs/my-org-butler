@IsTest
private class DataLibrary_Test {

    private static final String CHUNK_DMO = 'TestChunk_chunk__dlm';
    private static MockDataLibrary mock = new MockDataLibrary();

    static {
        DataCloudSql.mockedResponse = '{"data":[],"metadata":[]}';
    }


    @IsTest
    private static void returnsEmptyOnNoMatch() {

        // Setup
        mock.whenQueryContains('hybrid_search', createQueryResult(new List<List<Object>>()));


        // Exercise
        DataLibrary.Result result = mock.retrieve('test query', CHUNK_DMO, false);


        // Verify
        Assert.areEqual('', result.documents);
    }


    @IsTest
    private static void returnsDocumentContent() {

        // Setup
        mock.whenQueryContains('hybrid_search', createQueryResult(new List<List<Object>>{
            new List<Object>{ 'doc1' }
        }));

        mock.whenQueryContains('Chunk__c', createQueryResult(new List<List<Object>>{
            new List<Object>{ '1JDRt000001/policy.pdf', 'First chunk' },
            new List<Object>{ '1JDRt000001/policy.pdf', 'Second chunk' }
        }));


        // Exercise
        DataLibrary.Result result = mock.retrieve('discount policy', CHUNK_DMO, false);


        // Verify
        List<Object> documents = (List<Object>) JSON.deserializeUntyped(result.documents);
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
        DataLibrary.Result result = mock.retrieve('company docs', CHUNK_DMO, false);


        // Verify
        List<Object> documents = (List<Object>) JSON.deserializeUntyped(result.documents);
        Assert.areEqual(2, documents.size());
    }


    @IsTest
    private static void handlesNullData() {

        // Setup
        DataLibrary.QueryResult queryResult = new DataLibrary.QueryResult();
        queryResult.data = null;
        mock.whenQueryContains('hybrid_search', queryResult);


        // Exercise
        DataLibrary.Result result = mock.retrieve('test query', CHUNK_DMO, false);


        // Verify
        Assert.areEqual('', result.documents);
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
        DataLibrary.Result result = mock.retrieve('test query', CHUNK_DMO, false);


        // Verify
        Assert.isTrue(result.documents.contains('Valid content'));
    }


    @IsTest
    private static void derivesSearchIndex() {

        // Setup
        mock.whenQueryContains('hybrid_search', createQueryResult(new List<List<Object>>()));


        // Exercise
        mock.retrieve('test', 'ADL_MyOrgButlerLibr_chunk__dlm', false);


        // Verify
        Assert.isTrue(mock.lastQuery().contains('ADL_MyOrgButlerLibr_index__dlm'));
    }


    @IsTest
    private static void defaultSimilarityThreshold() {

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


    @IsTest
    private static void returnsEmptyOnException() {

        // Exercise
        DataLibrary.Result result = new ThrowingDataLibrary().retrieve('test query', CHUNK_DMO, false);


        // Verify
        Assert.areEqual('', result.documents);
        Assert.areEqual(null, result.citations);
    }


    // HELPER

    private static DataLibrary.QueryResult createQueryResult(List<List<Object>> rows) {
        DataLibrary.QueryResult result = new DataLibrary.QueryResult();
        result.data = new List<DataLibrary.QueryRow>();

        for (List<Object> rowData : rows) {
            DataLibrary.QueryRow row = new DataLibrary.QueryRow();
            row.rowData = rowData;
            result.data.add(row);
        }

        return result;
    }


    private class MockDataLibrary extends DataLibrary {
        private List<String> executedQueries = new List<String>();
        private Map<String, DataLibrary.QueryResult> responses = new Map<String, DataLibrary.QueryResult>();

        public void whenQueryContains(String pattern, DataLibrary.QueryResult result) {
            responses.put(pattern, result);
        }

        public String lastQuery() {
            return executedQueries.isEmpty() ? null : executedQueries[executedQueries.size() - 1];
        }

        protected override DataLibrary.QueryResult queryCdp(String sql) {
            DataLibrary.QueryResult result = null;

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


    private class ThrowingDataLibrary extends DataLibrary {

        protected override DataLibrary.QueryResult queryCdp(String sql) {
            throw new QueryException('Data Cloud not available');
        }
    }
}
