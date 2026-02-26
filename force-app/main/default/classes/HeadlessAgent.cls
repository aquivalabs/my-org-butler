public with sharing class HeadlessAgent {

    private String agentName;
    private String sessionId;


    // CONSTRUCTOR

    public HeadlessAgent(String agentName) {
        this.agentName = agentName;
    }


    // PUBLIC

    public Response send(String userMessage) {
        Response result = send(userMessage, new Map<String, String>());

        return result;
    }


    public Response send(String userMessage, Map<String, String> contextVariables) {
        Response result = invokeAgent(userMessage, contextVariables);

        if(result.success) {
            sessionId = result.sessionId;
        }

        return result;
    }


    // PRIVATE

    private Response invokeAgent(String userMessage, Map<String, String> contextVariables) {
        Response result = new Response();

        if(!Test.isRunningTest()) {
            Invocable.Action action = Invocable.Action.createCustomAction('generateAiAgentResponse', agentName);
            action.setInvocationParameter('userMessage', userMessage);

            if(sessionId != null) {
                action.setInvocationParameter('sessionId', sessionId);
            }

            for(String key : contextVariables.keySet()) {
                action.setInvocationParameter(key, contextVariables.get(key));
            }

            List<Invocable.Action.Result> results = action.invoke();
            Invocable.Action.Result actionResult = results[0];

            if(actionResult.isSuccess()) {
                result.text = (String) actionResult.getOutputParameters().get('agentResponse');
                result.sessionId = (String) actionResult.getOutputParameters().get('sessionId');
                result.success = true;
            }
            else {
                result.success = false;
                result.error = String.valueOf(actionResult.getErrors());
            }
        }
        else {
            result.text = 'Mock agent response';
            result.sessionId = 'mock-session-id';
            result.success = true;
        }

        return result;
    }


    // INNER

    public class Response {
        public String text;
        public String sessionId;
        public Boolean success;
        public String error;
    }
}
