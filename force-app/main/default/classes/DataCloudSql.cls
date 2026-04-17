@SuppressWarnings('PMD.ApexSuggestUsingNamedCred')
public with sharing class DataCloudSql {

    private static final String QUERY_ENDPOINT = '/services/data/v66.0/ssot/query-sql';

    @TestVisible
    private static String mockedResponse;


    public static String query(String sql) {

        System.debug('sql >>' + sql);
        if (Test.isRunningTest() && mockedResponse != null) {
            return mockedResponse;
        }

        HttpRequest request = new HttpRequest();
        request.setMethod('POST');
        request.setHeader('Authorization', 'Bearer ' + new SessionId().asString());
        request.setHeader('Content-Type', 'application/json');
        request.setEndpoint(Url.getOrgDomainURL().toExternalForm() + QUERY_ENDPOINT);
        request.setBody(JSON.serialize(new Map<String, String>{ 'sql' => sql }));

        HttpResponse response = new Http().send(request);

        if (response.getStatusCode() >= 400) {
            throw new DataCloudException('Data Cloud query error (' + response.getStatusCode() + '): ' + response.getBody());
        }

        return response.getBody();
    }


    public class DataCloudException extends Exception {}
}
