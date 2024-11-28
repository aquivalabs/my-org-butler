@SuppressWarnings('PMD.ApexSuggestUsingNamedCred')
global with sharing class SearchWebTool extends MyOrgButler.Tool {

    public override String execute(String paramsJson) {
        JsonParse parser = new JsonParse(paramsJson);

        SearchWeb.Query query = new SearchWeb.Query();
        query.content = parser.get('query').getStringValue();

        List<SearchWeb.Answer> result = SearchWeb.execute(new List<SearchWeb.Query>{ query });
        return JSON.serialize(result[0]);
    }
}
