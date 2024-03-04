// PMD False Positive: API properties require underscores
@SuppressWarnings('PMD.FieldNamingConventions')
public class Run {

    public String id;
    public String assistant_id;
    public String thread_id;
    public String status;
    public RequiredAction required_action;
    public String additional_instructions;

    // PUBLIC

    public Run(String threadId, String assistantId) {
        thread_id = threadId;
        assistant_id = assistantId;
        required_action = new RequiredAction();
    }

    public static Run create(String threadId, Run run) {
        Map<String, Object> payload = new Map<String, Object>();
        payload.put('assistant_id', run.assistant_id);
        payload.put('additional_instructions', run.additional_instructions);

        return (Run) new OpenAiApi('/threads/' +  threadId + '/runs')
                            .body(payload)
                            .post(Run.class);
    }

    public static Run retrieve(String threadId, String runId) {
        return (Run) new OpenAiApi('/threads/' +  threadId + '/runs/' +  runId)
                            .get(Run.class);
    }

    public static Steps steps(String threadId, String runId, Params params) {
        return (Steps) new OpenAiApi('/threads/' +  threadId + '/runs/' +  runId + '/steps' + params.asQueryString())
                            .get(Steps.class);
    }

    public Steps steps() {
        return steps(thread_id, id, new Params());
    }

    public Run id(String value) {
        id = value;
        return this;
    }

    public Run status(String value) {
        status = value;
        return this;
    }

    public Boolean isPending() {
        return (new Set<String>{ 'queued', 'in_progress' }.contains(status));
    }

    public Boolean requestsTool() {
        return (status == 'requires_action' && required_action.type == 'submit_tool_outputs');
    }

    public Boolean isCompletedOrFailed() {
        return (new Set<String>{ 'completed', 'failed' }.contains(status));
    }

    // INNER

    public class RequiredAction {
        public SubmitToolOutputs submit_tool_outputs = new SubmitToolOutputs() ;
        public String type;
    }

    public class SubmitToolOutputs {
        public List<ToolCall> tool_calls = new List<ToolCall>();
    }

    public class ToolCall {
        public String id;
        public ToolFn function = new ToolFn();

        public ToolCall(String name, String arguments) {
            function.name = name;
            function.arguments = arguments;
        }
    }
    
    public class ToolFn {
        public String name;
        public String arguments;
    }

    public class ToolOutputs {
        public List<ToolOutput> tool_outputs;

        public ToolOutputs(List<ToolOutput> toolOutputs){
            tool_outputs = toolOutputs;
        }
    }

    public class ToolOutput {
        public String tool_call_id;
        public String output;

        public ToolOutput(String toolCallId) {
            tool_call_id = toolCallId;
        }
    }

    public class Steps {
        @AuraEnabled public String first_id;
        @AuraEnabled public String last_id;
        @AuraEnabled public Boolean has_more = false;
        @AuraEnabled public List<Step> data = new List<Step>();

        public Steps(String status) {
            Step step = new Step();
            step.status = status;
            data.add(step);
        }
    }

    public class Step {
        @AuraEnabled public String id;
        @AuraEnabled public String type;
        @AuraEnabled public String status;
        @AuraEnabled public StepDetails step_details;
    }

    public class StepDetails {
        @AuraEnabled public String type;
        @AuraEnabled public StepDetailsMessageCreation message_creation;
        @AuraEnabled public List<StepDetailsToolCall> tool_calls;
    }

    public class StepDetailsMessageCreation {
        @AuraEnabled public String message_id;
    }

    public class StepDetailsToolCall {
        @AuraEnabled public String type;
        @AuraEnabled public StepDetailsToolCallFunction function;
        @AuraEnabled public String output;
    }

    public class StepDetailsToolCallFunction {
        @AuraEnabled public String arguments;
        @AuraEnabled public String name;
        @AuraEnabled public String output;
    }
}