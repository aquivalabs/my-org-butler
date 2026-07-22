ExploreDataCloud.Input inp = new ExploreDataCloud.Input();
inp.scope = 'summary';
String resp = ExploreDataCloud.execute(new List<ExploreDataCloud.Input>{ inp })[0].response;
for(String tok : resp.split('"')) {
    if(tok.endsWith('_chunk__dlm')) {
        ConnectApi.CdpQueryInput q = new ConnectApi.CdpQueryInput();
        q.sql = 'SELECT COUNT(*) FROM ' + tok;
        ConnectApi.CdpQueryOutputV2 r = ConnectApi.CdpQuery.queryANSISqlV2(q);
        if(r.data != null && !r.data.isEmpty() && String.valueOf(r.data[0].rowData[0]) != '0') {
            System.debug('READY');
            break;
        }
    }
}
