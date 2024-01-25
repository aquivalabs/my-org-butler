public class OpenAiApi {

    private HttpRequest request;

    // CONSTRUCTOR

    // PMD False Positive: Named Credential is used but not recognized
    @SuppressWarnings('PMD.ApexSuggestUsingNamedCred')
    public OpenAiApi(String urlFragment) {
        request = new HttpRequest();
        request.setEndpoint('callout:OpenAiApi/v1' + urlFragment);
        request.setHeader('Content-Type', 'application/json');
        request.setHeader('Authorization', 'Bearer {!$Credential.OpenAiApi.ApiKey}');
        request.setHeader('OpenAI-Beta', 'assistants=v1');
    }

    // PUBLIC

    public OpenAiApi body(Object payload) {
        request.setBody(JSON.serialize(payload));
        return this;
    }

    public Object get(Type type) {
        request.setMethod('GET');
        return callout(type);
    }

    public void get() {
        get(null);
    }

    public Object post(Type type) {
        request.setMethod('POST');
        return callout(type);
    }

    public void post() {
        post(null);
    }

    public void remove() {
        request.setMethod('DELETE');
        callout();
    }

    // PRIVATE 

    private HttpResponse callout() {
        HttpResponse response = null;

        try {
            response = new Http().send(request);
            if(response.getStatusCode() != 200) {
                throw new ApplicationException('Code: ' + response.getStatusCode() + ', Message: ' + response.getBody() + '.');
            }
        } 
        catch(Exception error) {
            throw new ApplicationException('Failed calling ' + request.getEndpoint() + ' :' + error.getMessage(), error);
        }

        return response;
    }


    private Object callout(Type type) {
        String result = callout().getBody();
        return (type != null) ? JSON.deserialize(result, type) : result;
    }
}