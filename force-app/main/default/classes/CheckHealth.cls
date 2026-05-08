// Note: Agentforce requires Global
@SuppressWarnings('PMD.AvoidGlobalModifier')
global with sharing class CheckHealth {

    @InvocableMethod(label='MyOrgButler: Check Health' description='Probe each dependency and return a one-line-per-dependency status report.')
    global static List<Output> execute() {
        Output result = new Output();
        result.report = String.join(new List<String>{
            probeTavilyCredential(),
            probeDataCloud()
        }, '\n');

        return new List<Output>{ result };
    }


    // PRIVATE

    private static String probeTavilyCredential() {
        String result;

        try {
            SearchWeb.Query q = new SearchWeb.Query();
            q.content = 'ping';
            SearchWeb.execute(new List<SearchWeb.Query>{ q });
            result = 'Tavily (Web Search): OK';
        }
        catch (Exception ex) {
            result = 'Tavily (Web Search): FAIL - ' + ex.getMessage();
        }

        return result;
    }


    private static String probeDataCloud() {
        String result;

        try {
            DataCloudSql.query('SELECT 1');
            result = 'Data Cloud: OK';
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
