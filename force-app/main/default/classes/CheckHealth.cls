// PMD False Positives:
// - Agentforce requires Global
// - Session auth is used for Salesforce REST API and Data Cloud probes; Named Credentials are not applicable there
@SuppressWarnings('PMD.AvoidGlobalModifier, PMD.ApexSuggestUsingNamedCred')
global with sharing class CheckHealth {

    @InvocableMethod(label='MyOrgButler: Check Health' description='Probe each dependency and return a one-line-per-dependency status report.')
    global static List<Output> execute() {
        Output result = new Output();
        result.report = String.join(new List<String>{
            probeRestApi(),
            probeTavilyCredential(),
            probeDataCloud()
        }, '\n');

        return new List<Output>{ result };
    }


    // PRIVATE

    private static String probeRestApi() {
        String result;

        try {
            HttpRequest request = new HttpRequest();
            request.setHeader('Authorization', 'Bearer ' + new SessionId().asString());
            request.setEndpoint(Url.getOrgDomainURL().toExternalForm() + '/services/data/');
            request.setMethod('GET');

            Integer code = new Http().send(request).getStatusCode();
            result = code < 400 ? 'Salesforce REST API: OK' : 'Salesforce REST API: HTTP ' + code;
        }
        catch (Exception ex) {
            result = 'Salesforce REST API: FAIL - ' + ex.getMessage();
        }

        return result;
    }


    private static String probeTavilyCredential() {
        String result;

        try {
            HttpRequest request = new HttpRequest();
            request.setEndpoint('callout:aquiva_os__TavilyApi/search');
            request.setMethod('POST');
            request.setHeader('Content-Type', 'application/json');
            request.setBody(JSON.serialize(new Map<String, Object>{
                'query' => 'ping',
                'api_key' => '{!$Credential.TavilyApi.ApiKey}',
                'include_answer' => true
            }));

            Integer code = new Http().send(request).getStatusCode();
            result = code < 400 ? 'Tavily (Web Search): OK' : 'Tavily (Web Search): HTTP ' + code;
        }
        catch (Exception ex) {
            result = 'Tavily (Web Search): FAIL - ' + ex.getMessage();
        }

        return result;
    }


    private static String probeDataCloud() {
        String result;

        try {
            HttpRequest request = new HttpRequest();
            request.setMethod('POST');
            request.setHeader('Authorization', 'Bearer ' + new SessionId().asString());
            request.setHeader('Content-Type', 'application/json');
            request.setEndpoint(Url.getOrgDomainURL().toExternalForm() + '/services/data/v66.0/ssot/query-sql');
            request.setBody(JSON.serialize(new Map<String, String>{ 'sql' => 'SELECT 1' }));

            Integer code = new Http().send(request).getStatusCode();
            // Note: 400 means the endpoint is up but rejected our trivial SQL — connectivity is fine
            result = code < 500 ? 'Data Cloud: OK' : 'Data Cloud: HTTP ' + code;
        }
        catch (Exception ex) {
            result = 'Data Cloud: FAIL - ' + ex.getMessage();
        }

        return result;
    }


    // INNER

    global class Output {
        @InvocableVariable(label='Health Report' description='Status of each dependency, one line per probe.')
        global String report;
    }
}
