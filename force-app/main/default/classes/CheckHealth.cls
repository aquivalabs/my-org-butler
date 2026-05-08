// PMD False Positives:
// - AvoidGlobalModifier: Agentforce requires Global
// - ApexSuggestUsingNamedCred: REST and Tooling API probes use session auth to call the org's own APIs
@SuppressWarnings('PMD.AvoidGlobalModifier,PMD.ApexSuggestUsingNamedCred')
global with sharing class CheckHealth {

    @InvocableMethod(label='MyOrgButler: Check Health' description='Probes each agent dependency and returns a report listing which connections and services are working.')
    global static List<Output> execute(List<String> ignored) {
        List<ProbeResult> results = new List<ProbeResult>();

        results.add(probeRestApi());
        results.add(probeToolingApi());
        results.add(probeTavilyApi());
        results.add(probeDataCloud());
        results.add(probeMemory());
        results.add(probeCustomSettings());

        Output out = new Output();
        out.report = formatReport(results);
        return new List<Output>{ out };
    }


    // PRIVATE

    private static ProbeResult probeRestApi() {
        ProbeResult result;
        try {
            HttpRequest request = new HttpRequest();
            request.setHeader('Authorization', 'Bearer ' + new SessionId().asString());
            request.setMethod('GET');
            request.setEndpoint(Url.getOrgDomainURL().toExternalForm() + '/services/data/');

            HttpResponse response = new Http().send(request);
            Integer status = response.getStatusCode();

            if (status == 200) {
                result = new ProbeResult('Salesforce REST API', 'OK', null);
            } else {
                result = new ProbeResult('Salesforce REST API', 'ERROR', 'HTTP ' + status + ': ' + response.getBody());
            }
        } catch (Exception e) {
            result = new ProbeResult('Salesforce REST API', 'ERROR', e.getMessage());
        }
        return result;
    }

    private static ProbeResult probeToolingApi() {
        ProbeResult result;
        try {
            CallToolingApi.query('SELECT Id FROM AsyncApexJob LIMIT 1');
            result = new ProbeResult('Tooling API', 'OK', null);
        } catch (Exception e) {
            result = new ProbeResult('Tooling API', 'ERROR', e.getMessage());
        }
        return result;
    }

    private static ProbeResult probeTavilyApi() {
        ProbeResult result;
        try {
            HttpRequest request = new HttpRequest();
            request.setEndpoint('callout:TavilyApi/search');
            request.setMethod('POST');
            request.setHeader('Content-Type', 'application/json');
            request.setBody(JSON.serialize(new Map<String, Object>{
                'query' => 'health check',
                'api_key' => '{!$Credential.TavilyApi.ApiKey}',
                'include_answer' => false,
                'max_results' => 1
            }));

            HttpResponse response = new Http().send(request);
            Integer status = response.getStatusCode();

            if (status >= 200 && status < 300) {
                result = new ProbeResult('Named Credential TavilyApi', 'OK', null);
            } else {
                result = new ProbeResult('Named Credential TavilyApi', 'ERROR', 'HTTP ' + status + ': ' + response.getBody());
            }
        } catch (Exception e) {
            result = new ProbeResult('Named Credential TavilyApi', 'ERROR', e.getMessage());
        }
        return result;
    }

    private static ProbeResult probeDataCloud() {
        ProbeResult result;
        try {
            DataCloudSql.query('SELECT 1');
            result = new ProbeResult('Data Cloud', 'OK', null);
        } catch (DataCloudSql.DataCloudException e) {
            // Any DataCloudException means the endpoint responded (connection is up);
            // the query itself may be invalid — that is not a connectivity failure.
            result = new ProbeResult('Data Cloud', 'OK', 'Endpoint reachable');
        } catch (Exception e) {
            result = new ProbeResult('Data Cloud', 'ERROR', e.getMessage());
        }
        return result;
    }

    // PMD False Positive: ApexFlsViolation — WITH SYSTEM_MODE is required for health checks run by the agent session
    @SuppressWarnings('PMD.ApexFlsViolation')
    private static ProbeResult probeMemory() {
        ProbeResult result;
        try {
            Integer count = [SELECT COUNT() FROM Memory__c WITH SYSTEM_MODE];
            result = new ProbeResult('Memory Storage', 'OK', count + ' entries');
        } catch (Exception e) {
            result = new ProbeResult('Memory Storage', 'ERROR', e.getMessage());
        }
        return result;
    }

    // PMD False Positive: ApexFlsViolation — WITH SYSTEM_MODE is required for health checks run by the agent session
    @SuppressWarnings('PMD.ApexFlsViolation')
    private static ProbeResult probeCustomSettings() {
        ProbeResult result;
        try {
            Integer count = [SELECT COUNT() FROM CustomSetting__c WITH SYSTEM_MODE];
            result = new ProbeResult('Custom Settings', 'OK', count + ' configured');
        } catch (Exception e) {
            result = new ProbeResult('Custom Settings', 'ERROR', e.getMessage());
        }
        return result;
    }

    private static String formatReport(List<ProbeResult> results) {
        List<String> lines = new List<String>();
        lines.add('MyOrgButler Health Check');
        lines.add('========================');

        for (ProbeResult r : results) {
            String line = '[' + r.status + '] ' + r.name;
            if (String.isNotBlank(r.detail)) {
                line += ': ' + r.detail;
            }
            lines.add(line);
        }

        return String.join(lines, '\n');
    }


    // INNER

    global class Output {
        @InvocableVariable(label='Health Report' description='Status report listing each dependency probe and its outcome.')
        global String report;
    }

    private class ProbeResult {
        String name;
        String status;
        String detail;

        ProbeResult(String name, String status, String detail) {
            this.name = name;
            this.status = status;
            this.detail = detail;
        }
    }
}
