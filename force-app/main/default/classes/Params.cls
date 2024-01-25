public with sharing class Params {
    private Map<String, Object> params = new Map<String, Object>();

    public Params limitRecords(Integer value) {
        if(value != null){
            params.put('limit', value);
        }
        return this;
    }

    public Params order(String value) {
        if(value != null){
            params.put('order', value);
        }
        return this;
    }

    public Params afterRecord(String value) {
        if(value != null){
            params.put('after', value);
        }
        return this;
    }

    public Params beforeRecord(String value) {
        if(value != null){
            params.put('before', value);
        }
        return this;
    }

    public String asQueryString(){
        String result = '?';

        for(String key : params.keySet()) {
            result += key + '=' + params.get(key) + '&';
        }

        return (params.isEmpty()) ? result.removeStart('?') : result.removeEnd('&');
    }
}