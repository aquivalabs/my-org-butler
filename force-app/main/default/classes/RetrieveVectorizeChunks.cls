// PMD False Positives: Agentforce requires Global
@SuppressWarnings('PMD.AvoidGlobalMethod')
global with sharing class RetrieveVectorizeChunks {

    @InvocableMethod(label='MyOrgButler: Search External Knowledge' description='Use Vector Search to find relevant internal document chunks to answer users question.')
    global static List<Answer> execute(List<Question> questions) {
        Answer result = new Answer();
        result.content = getAnswer(questions[0].content);

        return new List<Answer>{ result };
    }

    // PRIVATE

    private static String getAnswer(String userQuestion) {
        List<Chunk> chunks = retrieveFromVectorize(userQuestion);
        return generateAnswer(userQuestion, chunks);
    }

    private static List<Chunk> retrieveFromVectorize(String query) {
        HttpRequest request = new HttpRequest();
        request.setEndpoint('callout:aquiva_os__VectorizeApi' + getEndpoint());
        request.setMethod('POST');
        request.setHeader('Content-Type', 'application/json');

        Map<String, Object> body = new Map<String, Object>{ 
            'question' => query,
            'rerank' => true,
            'numResults' => 10
        };
        request.setBody(JSON.serialize(body));

        HttpResponse response = new Http().send(request);
        
        if (response.getStatusCode() != 200) {
            throw new ApplicationException('External knowledge search failed: ' + response.getStatus());
        }

        return toChunks(response);
    }

    private static List<Chunk> toChunks(HttpResponse response) {
        List<Chunk> result = new List<Chunk>();

        Map<String, Object> responseData = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
        List<Object> documents = (List<Object>) responseData.get('documents');
        
        if(documents != null) {
            for(Object doc : documents) {
                Map<String, Object> docMap = (Map<String, Object>) doc;

                Chunk chunk = new Chunk();
                chunk.text = (String) docMap.get('text');
                chunk.source = (String) docMap.get('source_display_name');
                chunk.sourceUrl = getSourceUrl(docMap);
                chunk.relevancy = (Decimal) docMap.get('relevancy');

                result.add(chunk);
            }
        }
        
        return result;
    }

    private static String getSourceUrl(Map<String, Object> docMap) {
        Map<String, String> urlByOrigin = new Map<String, String>{
            'google-drive' => 'https://docs.google.com/file/d/',
            'confluence-bucket' => 'https://aquiva.atlassian.net/wiki/spaces/STAN/pages/'
        };

        String origin = (String) docMap.get('origin');
        String sourceId = (String) docMap.get('source');

        return urlByOrigin.get(origin) + sourceId;
    }

    private static String generateAnswer(String userQuestion, List<Chunk> chunks) {
        if(Test.isRunningTest()) {
            return 'Mock answer for testing: ' + userQuestion;
        }
        
        ConnectApi.WrappedValue questionParam = new ConnectApi.WrappedValue();
        questionParam.value = userQuestion;
        
        ConnectApi.WrappedValue chunksParam = new ConnectApi.WrappedValue();
        chunksParam.value = JSON.serialize(chunks);
        
        ConnectApi.EinsteinPromptTemplateGenerationsInput input = new ConnectApi.EinsteinPromptTemplateGenerationsInput();
        input.additionalConfig = new ConnectApi.EinsteinLlmAdditionalConfigInput();
        input.additionalConfig.applicationName = 'PromptBuilderPreview';
        input.isPreview = false;
        input.inputParams = new Map<String, ConnectApi.WrappedValue>{
            'Input:userQuestion' => questionParam,
            'Input:retrievedChunks' => chunksParam
        };
        
        ConnectApi.EinsteinPromptTemplateGenerationsRepresentation output = 
            ConnectApi.EinsteinLLM.generateMessagesForPromptTemplate('AnswerFromVectorizeChunks', input);
        
        return output.generations[0].text;
    }

    @TestVisible
    private static String getEndpoint() {
        String orgId = CustomSettings.valueFor('VectorizeOrgId');
        String pipelineId = CustomSettings.valueFor('VectorizePipelineId');

        return '/v1/org/' + orgId + '/pipelines/' + pipelineId + '/retrieval';
    }

    // INNER

    private class Chunk {
        public String text;
        public String source;
        public String sourceUrl;
        public Decimal relevancy;
    }

    global class Question {
        @InvocableVariable(label='Question' description='The question to search for in the company knowledge base.')
        global String content;
        
        global Question() {}
        
        global Question(String content) {
            this.content = content;
        }
    }

    global class Answer {
        @InvocableVariable(label='Answer' description='AI-generated answer based on company knowledge sources.')
        global String content;
    }
}