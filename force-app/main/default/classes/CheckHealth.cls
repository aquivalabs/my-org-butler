// PMD False Positives: Agentforce requires Global; session auth needed for internal API probes
@SuppressWarnings('PMD.AvoidGlobalModifier, PMD.ApexSuggestUsingNamedCred')
global with sharing class CheckHealth {

    @InvocableMethod(label='MyOrgButler: Check Health'
                     description='Run a self-check of all agent dependencies and return a status report for each.')
    global static List<Output> execute(List<String> ignored) {
        List<ProbeResult> probes = new List<ProbeResult>{
            probeRestApi(),
            probeDataCloud(),
            probeTavily(),
            probeMemoryObject(),
            probeCustomSettings()
        };

        Output output = new Output();
        output.report = JSON.serialize(probes, true);
        return new List<Output>{ output };
    }


    // PRIVATE

    private static ProbeResult probeRestApi() {
        ProbeResult result = new ProbeResult('Salesforce REST API');
        try {
            HttpRequest request = new HttpRequest();
            request.setMethod('GET');
            request.setHeader('Authorization', 'Bearer ' + new SessionId().asString());
            request.setEndpoint(Url.getOrgDomainURL().toExternalForm() + '/services/data/v66.0/');

            HttpResponse response = new Http().send(request);
            result.status = response.getStatusCode() < 400 ? 'ok' : 'error';
            result.detail = 'HTTP ' + response.getStatusCode();
        }
        catch (Exception ex) {
            result.status = 'error';
            result.detail = ex.getMessage();
        }
        return result;
    }


    private static ProbeResult probeDataCloud() {
        ProbeResult result = new ProbeResult('Data Cloud SSOT API');
        try {
            HttpRequest request = new HttpRequest();
            request.setMethod('GET');
            request.setHeader('Authorization', 'Bearer ' + new SessionId().asString());
            request.setHeader('Content-Type', 'application/json');
            request.setEndpoint(Url.getOrgDomainURL().toExternalForm() + '/services/data/v66.0/ssot/metadata');

            HttpResponse response = new Http().send(request);
            result.status = response.getStatusCode() < 400 ? 'ok' : 'error';
            result.detail = 'HTTP ' + response.getStatusCode();
        }
        catch (Exception ex) {
            result.status = 'error';
            result.detail = ex.getMessage();
        }
        return result;
    }


    private static ProbeResult probeTavily() {
        ProbeResult result = new ProbeResult('Named Credential: TavilyApi');
        try {
            HttpRequest request = new HttpRequest();
            request.setMethod('POST');
            request.setEndpoint('callout:aquiva_os__TavilyApi/search');
            request.setHeader('Content-Type', 'application/json');
            request.setBody(JSON.serialize(new Map<String, Object>{
                'query' => 'health check',
                'api_key' => '{!$Credential.TavilyApi.ApiKey}'
            }));

            HttpResponse response = new Http().send(request);
            result.status = response.getStatusCode() < 400 ? 'ok' : 'error';
            result.detail = 'HTTP ' + response.getStatusCode();
        }
        catch (Exception ex) {
            result.status = 'error';
            result.detail = ex.getMessage();
        }
        return result;
    }


    // PMD False Positives: SOQL uses WITH SYSTEM_MODE to check object accessibility regardless of user FLS
    @SuppressWarnings('PMD.ApexFlsViolation')
    private static ProbeResult probeMemoryObject() {
        ProbeResult result = new ProbeResult('Memory__c object');
        try {
            Integer count = [SELECT COUNT() FROM Memory__c WITH SYSTEM_MODE];
            result.status = 'ok';
            result.detail = count + ' record(s)';
        }
        catch (Exception ex) {
            result.status = 'error';
            result.detail = ex.getMessage();
        }
        return result;
    }


    // PMD False Positives: SOQL uses WITH SYSTEM_MODE to check object accessibility regardless of user FLS
    @SuppressWarnings('PMD.ApexFlsViolation')
    private static ProbeResult probeCustomSettings() {
        ProbeResult result = new ProbeResult('CustomSetting__c object');
        try {
            Integer count = [SELECT COUNT() FROM CustomSetting__c WITH SYSTEM_MODE];
            result.status = 'ok';
            result.detail = count + ' record(s)';
        }
        catch (Exception ex) {
            result.status = 'error';
            result.detail = ex.getMessage();
        }
        return result;
    }


    // INNER

    global class Output {
        @InvocableVariable(label='Health Report' description='JSON array of probe results, one per dependency checked.')
        global String report;
    }

    private class ProbeResult {
        public String name;
        public String status;
        public String detail;

        private ProbeResult(String name) {
            this.name = name;
        }
    }
}
