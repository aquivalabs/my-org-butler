/**
 * @author aidan@nebulaconsulting.co.uk
 * @date 19/06/2020
 * @description Read keys from a JSON object by specifying the path. Suitable for only a small number of reads as
 * each one is found independently
 */

public class JsonReader {

    private Object theData;
    private Object missingKeyResult = null;

    private static final Pattern JSON_SEARCH_PATH_PATTERN = Pattern.compile('(\\[\\d+])|([\\w]+)');

    public JsonReader(String jsonString) {
        theData = JSON.deserializeUntyped(jsonString);
    }

    public JsonReader(Object untypedJsonObject) {
        theData = untypedJsonObject;
    }

    public JsonReader setMissingKeyResult(Object missingKeyResult) {
        this.missingKeyResult = missingKeyResult;
        return this;
    }

    public Object read(String jsonPath) {
        return read(new RegexFindIterator(JSON_SEARCH_PATH_PATTERN, jsonPath), theData);
    }

    private Object read(RegexFindIterator jsonPathIterator, Object thisData) {
        String thisKey = jsonPathIterator.next();

        Object nextData = thisKey.contains('[') ?
                readFromList((List<Object>)thisData, thisKey)
                :
                readFromMap((Map<String, Object>)thisData, thisKey);

        if(nextData != null && nextData != missingKeyResult && jsonPathIterator.hasNext()) {
            return read(jsonPathIterator, nextData);
        } else {
            return nextData;
        }
    }

    private Object readFromMap(Map<String, Object> dataAsMap, String thisKey) {
        return dataAsMap.containsKey(thisKey) ? dataAsMap.get(thisKey) : missingKeyResult;
    }

    private Object readFromList(List<Object> dataAsList, String thisKey) {
        Integer index = Integer.valueOf(thisKey.substring(1, thisKey.length() - 1));
        if (index < dataAsList.size()) {
            return dataAsList[index];
        } else {
            return missingKeyResult;
        }
    }
}