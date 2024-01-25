@IsTest
private class HttpMock_Test {
    private static final PersonApi API = new PersonApi();
    private static final Person JOE = new Person('joe');
    private static final Person TIM = new Person('tim');

    @IsTest
    private static void multipleEndpointFragments() {
        // Setup
        new HttpMock().get('/v2/persons', new List<Person>{ JOE, TIM }, 200).get('/v2/person/tim', TIM, 200).mock();

        // Exercise + Verify
        Test.startTest();

        System.assertEquals(2, API.getPersons().size());
        System.assertEquals('tim', API.getPerson('tim').name);

        Test.stopTest();
    }

    @IsTest
    private static void multipleHttpMethods() {
        // Setup
        new HttpMock().get('/v2/person/tim', TIM, 200).post('/v2/person/tim', true, 200).mock();

        // Exercise + Verify
        Test.startTest();

        System.assertEquals(true, API.updatePerson(new Person('tim')));
        System.assertEquals('tim', API.getPerson('tim').name);

        Test.stopTest();
    }

    @IsTest
    private static void bodyConditions() {
        // Setup
        new HttpMock().post('/v2/person/tim#"age":33', true, 200).post('/v2/person/tim#"age":null', false, 200).mock();

        // Exercise + Verify
        Test.startTest();
        System.assertEquals(true, API.updatePerson(TIM));

        TIM.age = null;
        System.assertEquals(false, API.updatePerson(TIM));
        Test.stopTest();
    }

    @IsTest
    private static void fail() {
        // Setup
        new HttpMock().get('/v2/persons', new CalloutException()).mock();

        // Exercise + Verify
        try {
            Test.startTest();
            API.getPersons();
            Test.stopTest();

            System.assert(false);
        } catch (CalloutException ex) {
            System.assert(true);
        }
    }

    // HELPER

    private class PersonApi {
        private final String BASE_URL = 'https://test.api.com';

        public List<Person> getPersons() {
            HttpRequest request = new HttpRequest();
            request.setEndpoint(BASE_URL + '/v2/persons');
            request.setMethod('GET');
            return (List<Person>) JSON.deserialize(new Http().send(request).getBody(), List<Person>.class);
        }

        public Person getPerson(String name) {
            HttpRequest request = new HttpRequest();
            request.setMethod('GET');
            request.setEndpoint(BASE_URL + '/v2/person/' + name);
            return (Person) JSON.deserialize(new Http().send(request).getBody(), Person.class);
        }

        public Boolean updatePerson(Person person) {
            HttpRequest request = new HttpRequest();
            request.setMethod('POST');
            request.setEndpoint(BASE_URL + '/v2/person/' + person.name);
            request.setHeader('Content-Type', 'application/json');
            request.setBody(JSON.serialize(person));
            return Boolean.valueOf(new Http().send(request).getBody());
        }
    }

    private class Person {
        public String name;
        public Integer age = 33;

        public Person(String name) {
            this.name = name;
        }
    }
}
