/**
 * @author aidan@nebulaconsulting.co.uk
 * @date 19/06/2020
 */

@IsTest
private class JsonReaderTest {

    @IsTest
    static void singleKey() {
        String jsonString = '{"a": "expected"}';

        Test.startTest();
        Object result = new JsonReader(jsonString).read('a');
        Test.stopTest();

        System.assertEquals('expected', result);
    }

    @IsTest
    static void nestedKey() {
        String jsonString = '{"a": { "a2": "expected"} }';

        Test.startTest();
        Object result = new JsonReader(jsonString).read('a.a2');
        Test.stopTest();

        System.assertEquals('expected', result);
    }

    @IsTest
    static void withList() {
        String jsonString = '{"a": { "a2": ["x", "expected"] } }';

        Test.startTest();
        Object result = new JsonReader(jsonString).read('a.a2[1]');
        Test.stopTest();

        System.assertEquals('expected', result);
    }

    @IsTest
    static void twoDimensionalList() {
        String jsonString = '{"a": { "a2": ["x", ["expected"]] } }';

        Test.startTest();
        Object result = new JsonReader(jsonString).read('a.a2[1][0]');
        Test.stopTest();

        System.assertEquals('expected', result);
    }

    @IsTest
    static void mixedListsAndNesting() {
        String jsonString = '{"a": { "a2": ["x", { "b": [["expected"]] } ] } }';

        Test.startTest();
        Object result = new JsonReader(jsonString).read('a.a2[1].b[0][0]');
        Test.stopTest();

        System.assertEquals('expected', result);
    }

    @IsTest
    static void missingKey() {
        String jsonString = '{"a": { "a2": "expected"} }';
        final String NO_RESULT = 'no result';
        Test.startTest();
        Object result = new JsonReader(jsonString)
                .setMissingKeyResult(NO_RESULT)
                .read('a.nope');
        Test.stopTest();

        System.assertEquals(NO_RESULT, result);
    }
}