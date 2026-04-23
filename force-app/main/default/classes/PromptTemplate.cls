public with sharing class PromptTemplate {

    private String templateName;

    @TestVisible
    private static String mockedResult = 'Test Generated Content Lorem Ipsum';

    @TestVisible
    private static Boolean throwOnNextCall = false;

    // CONSTRUCTORS

    public PromptTemplate(String templateName) {
        this.templateName = templateName;
    }

    // PUBLIC

    public Result call(Map<String, Object> inputParams) {
        if (throwOnNextCall) {
            throwOnNextCall = false;
            throw new PromptTemplateException('Mocked failure for ' + templateName);
        }

        Result result = new Result();
        result.text = mockedResult;

        if(!Test.isRunningTest()) {
            ConnectApi.EinsteinPromptTemplateGenerationsRepresentation output = invokeTemplate(templateName, inputParams);
            validateOutput(output, templateName);
            result.text = output.generations[0].text;
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


    // INNER

    public class Result {
        public String text;
    }

    public class PromptTemplateException extends Exception {}
}
