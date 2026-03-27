public with sharing class PromptTemplate {

    private String templateName;

    @TestVisible
    private static String mockedResult = 'Test Generated Content Lorem Ipsum';

    // CONSTRUCTORS

    public PromptTemplate(String templateName) {
        this.templateName = templateName;
    }

    // PUBLIC

    public Result call(Map<String, Object> inputParams) {
        Result result = new Result();
        result.text = mockedResult;

        if(!Test.isRunningTest()) {
            ConnectApi.EinsteinPromptTemplateGenerationsRepresentation output = invokeTemplate(templateName, inputParams);
            validateOutput(output, templateName);
            result.text = output.generations[0].text;
            result.citations = toGenAiCitation(output.citations?.sourceReferences);
        }

        return result;
    }


    // PRIVATE

    private static void validateOutput(ConnectApi.EinsteinPromptTemplateGenerationsRepresentation output, String templateName) {
        if (hasGenerationErrors(output)) {
            throw new PromptTemplateException(buildErrorMessage(output.generationErrors));
        }

        if (hasNoGenerations(output)) {
            throw new PromptTemplateException('No generations returned from: ' + templateName);
        }
    }

    private static Boolean hasGenerationErrors(ConnectApi.EinsteinPromptTemplateGenerationsRepresentation output) {
        return output.generationErrors != null && !output.generationErrors.isEmpty();
    }

    private static Boolean hasNoGenerations(ConnectApi.EinsteinPromptTemplateGenerationsRepresentation output) {
        return output.generations == null || output.generations.isEmpty();
    }

    private ConnectApi.EinsteinPromptTemplateGenerationsRepresentation invokeTemplate(String templateName, Map<String, Object> inputParams) {
        Map<String, ConnectApi.WrappedValue> params = new Map<String, ConnectApi.WrappedValue>();
        for(String key : inputParams.keySet()) {
            params.put(key, wrap(inputParams.get(key)));
        }

        ConnectApi.EinsteinPromptTemplateGenerationsInput input = new ConnectApi.EinsteinPromptTemplateGenerationsInput();
        input.additionalConfig = new ConnectApi.EinsteinLlmAdditionalConfigInput();
        input.additionalConfig.applicationName = 'PromptBuilderPreview';
        input.isPreview = false;
        input.inputParams = params;
        input.citationMode = 'post_generation';

        return ConnectApi.EinsteinLLM.generateMessagesForPromptTemplate(templateName, input);
    }

    private static String buildErrorMessage(List<ConnectApi.EinsteinPromptTemplateGenerationsError> errors) {
        List<String> result = new List<String>();

        for(ConnectApi.EinsteinPromptTemplateGenerationsError error : errors) {
            result.add(error.errorMessage);
        }

        return String.join(result, '; ');
    }


    private static ConnectApi.WrappedValue wrap(Object value) {
        ConnectApi.WrappedValue result = new ConnectApi.WrappedValue();
        Boolean isSObject = value instanceof SObject;
        result.value = isSObject ? new Map<String, String>{ 'id' => String.valueOf(((SObject) value).Id) } : value;

        return result;
    }


    private static AiCopilot.GenAiCitationInput toGenAiCitation(List<ConnectApi.EinsteinLlmGenAiSourceReference> sourceRefs) {
        List<AiCopilot.GenAiSourceReference> result = new List<AiCopilot.GenAiSourceReference>();

        if (sourceRefs != null) {
            for (ConnectApi.EinsteinLlmGenAiSourceReference sourceRef : sourceRefs) {
                List<AiCopilot.GenAiSourceContentInfo> contents = toGenAiSourceContentInfo(sourceRef.contents);
                List<AiCopilot.GenAiSourceReferenceInfo> metadata = toGenAiSourceReferenceInfo(sourceRef.metadata);

                result.add(new AiCopilot.GenAiSourceReference(null, contents, metadata));
            }
        }

        return new AiCopilot.GenAiCitationInput(null, result);
    }


    private static List<AiCopilot.GenAiSourceContentInfo> toGenAiSourceContentInfo(List<ConnectApi.EinsteinLlmGenerationGenAiSourceContentInfo> contentInfo) {
        List<AiCopilot.GenAiSourceContentInfo> result = new List<AiCopilot.GenAiSourceContentInfo>();

        for (ConnectApi.EinsteinLlmGenerationGenAiSourceContentInfo content : contentInfo) {
            result.add(new AiCopilot.GenAiSourceContentInfo(content.fieldName, content.objectName, content.content));
        }

        return result;
    }


    private static List<AiCopilot.GenAiSourceReferenceInfo> toGenAiSourceReferenceInfo(List<ConnectApi.EinsteinLlmGenerationGenAiSourceReferenceInfo> referenceInfos) {
        List<AiCopilot.GenAiSourceReferenceInfo> result = new List<AiCopilot.GenAiSourceReferenceInfo>();

        for (ConnectApi.EinsteinLlmGenerationGenAiSourceReferenceInfo referenceInfo : referenceInfos) {
            result.add(new AiCopilot.GenAiSourceReferenceInfo(referenceInfo.link, referenceInfo.sourceObjectRecordId, referenceInfo.sourceObjectApiName));
        }

        return result;
    }


    // INNER

    public class Result {
        public String text;
        public AiCopilot.GenAiCitationInput citations;
    }

    public class PromptTemplateException extends Exception {}
}
