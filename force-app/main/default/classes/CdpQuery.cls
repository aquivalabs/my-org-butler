public virtual with sharing class CdpQuery {

    public virtual ConnectApi.CdpQueryOutputV2 query(String sql) {
        ConnectApi.CdpQueryInput input = new ConnectApi.CdpQueryInput();
        input.sql = sql;
        return ConnectApi.CdpQuery.queryANSISqlV2(input);
    }
}