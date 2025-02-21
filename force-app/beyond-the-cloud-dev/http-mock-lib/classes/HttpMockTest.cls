/**
 * Copyright (c) 2024 Beyond The Cloud Sp. z o.o. (BeyondTheCloud.Dev)
 * Licensed under the MIT License (https://github.com/beyond-the-cloud-dev/http-mock-lib/blob/main/LICENSE)
**/
@IsTest
private class HttpMockTest {
    @IsTest
    static void get() {
        new HttpMock()
            .get('/api/v1')
            .mock();

        Test.startTest();
        HttpResponse response = new TestApi().makeCallout('GET', '/api/v1');
        Test.stopTest();

        Assert.areEqual(200, response.getStatusCode());
        Assert.areEqual('{}', response.getBody());
    }

    @IsTest
    static void post() {
        new HttpMock()
            .post('/api/v1')
            .mock();

        Test.startTest();
        HttpResponse response = new TestApi().makeCallout('POST', '/api/v1');
        Test.stopTest();

        Assert.areEqual(200, response.getStatusCode());
        Assert.areEqual('{}', response.getBody());
    }

    @IsTest
    static void put() {
        new HttpMock()
            .put('/api/v1')
            .mock();

        Test.startTest();
        HttpResponse response = new TestApi().makeCallout('PUT', '/api/v1');
        Test.stopTest();

        Assert.areEqual(200, response.getStatusCode());
        Assert.areEqual('{}', response.getBody());
    }

    @IsTest
    static void patch() {
         new HttpMock()
            .patch('/api/v1')
            .mock();

        Test.startTest();
        HttpResponse response = new TestApi().makeCallout('PATCH', '/api/v1');
        Test.stopTest();

        Assert.areEqual(200, response.getStatusCode());
        Assert.areEqual('{}', response.getBody());
    }

    @IsTest
    static void head() {
         new HttpMock()
            .head('/api/v1')
            .mock();

        Test.startTest();
        HttpResponse response = new TestApi().makeCallout('HEAD', '/api/v1');
        Test.stopTest();

        Assert.areEqual(200, response.getStatusCode());
        Assert.areEqual('{}', response.getBody());
    }

    @IsTest
    static void objectBody() {
        Map<String, Object> mockedObject = new Map<String, Object>{ 'name' => 'test' };

        new HttpMock()
            .get('/api/v1').body(mockedObject)
            .mock();

        Test.startTest();
        HttpResponse response = new TestApi().makeCallout('GET', '/api/v1');
        Test.stopTest();

        Assert.areEqual(mockedObject, (Map<String, Object>) JSON.deserializeUntyped(response.getBody()));
    }

    @IsTest
    static void stringBody() {
        String mockedString = JSON.serialize(new Map<String, String>{ 'name' => 'test' });

        new HttpMock()
            .get('/api/v1').body(mockedString)
            .mock();

        Test.startTest();
        HttpResponse response = new TestApi().makeCallout('GET', '/api/v1');
        Test.stopTest();

        Assert.areEqual(mockedString, response.getBody());
    }

    @IsTest
    static void blobBody() {
        Blob mockedBlob = Blob.valueof('Test Blob');

        new HttpMock()
            .get('/api/v1').body(mockedBlob)
            .mock();

        Test.startTest();
        HttpResponse response = new TestApi().makeCallout('GET', '/api/v1');
        Test.stopTest();

        Assert.areEqual(mockedBlob, response.getBodyAsBlob());
    }

    @IsTest
    static void primitiveBody() {
        Integer mockedInteger = 1;

        new HttpMock()
            .get('/api/v1').body(mockedInteger)
            .mock();

        Test.startTest();
        HttpResponse response = new TestApi().makeCallout('GET', '/api/v1');
        Test.stopTest();

        Assert.areEqual(mockedInteger, Integer.valueOf(response.getBody()));
    }

    @IsTest
    static void contentTypePlainText() {
        new HttpMock()
            .get('/api/v1').contentTypePlainText()
            .mock();

        Test.startTest();
        HttpResponse response = new TestApi().makeCallout('GET', '/api/v1');
        Test.stopTest();

        Assert.areEqual('text/plain', response.getHeader('Content-Type'));
    }

    @IsTest
    static void contentTypeHtml() {
        new HttpMock()
            .get('/api/v1').contentTypeHtml()
            .mock();

        Test.startTest();
        HttpResponse response = new TestApi().makeCallout('GET', '/api/v1');
        Test.stopTest();

        Assert.areEqual('text/html', response.getHeader('Content-Type'));
    }

    @IsTest
    static void contentTypeCsv() {
        new HttpMock()
            .get('/api/v1').contentTypeCsv()
            .mock();

        Test.startTest();
        HttpResponse response = new TestApi().makeCallout('GET', '/api/v1');
        Test.stopTest();

        Assert.areEqual('text/csv', response.getHeader('Content-Type'));
    }

    @IsTest
    static void contentTypeJson() {
        new HttpMock()
            .get('/api/v1').contentTypeJson()
            .mock();

        Test.startTest();
        HttpResponse response = new TestApi().makeCallout('GET', '/api/v1');
        Test.stopTest();

        Assert.areEqual('application/json', response.getHeader('Content-Type'));
    }

    @IsTest
    static void contentTypePdf() {
        new HttpMock()
            .get('/api/v1').contentTypePdf()
            .mock();

        Test.startTest();
        HttpResponse response = new TestApi().makeCallout('GET', '/api/v1');
        Test.stopTest();

        Assert.areEqual('application/pdf', response.getHeader('Content-Type'));
    }

    @IsTest
    static void contentTypeXml() {
        new HttpMock()
            .get('/api/v1').contentTypeXml()
            .mock();

        Test.startTest();
        HttpResponse response = new TestApi().makeCallout('GET', '/api/v1');
        Test.stopTest();

        Assert.areEqual('application/xml', response.getHeader('Content-Type'));
    }

    @IsTest
    static void contentTypeFormUrlencoded() {
        new HttpMock()
            .get('/api/v1').contentTypeFormUrlencoded()
            .mock();

        Test.startTest();
        HttpResponse response = new TestApi().makeCallout('GET', '/api/v1');
        Test.stopTest();

        Assert.areEqual('application/x-www-form-urlencoded', response.getHeader('Content-Type'));
    }

    @IsTest
    static void customContentType() {
        new HttpMock()
            .get('/api/v1').contentType('text/html')
            .mock();

        Test.startTest();
        HttpResponse response = new TestApi().makeCallout('GET', '/api/v1');
        Test.stopTest();

        Assert.areEqual('text/html', response.getHeader('Content-Type'));
    }

    @IsTest
    static void statusCodeOk() {
        new HttpMock()
            .get('/api/v1').statusCodeOk()
            .mock();

        Test.startTest();
        HttpResponse response = new TestApi().makeCallout('GET', '/api/v1');
        Test.stopTest();

        Assert.areEqual(200, response.getStatusCode());
    }

    @IsTest
    static void statusCodeCreated() {
        new HttpMock()
            .get('/api/v1').statusCodeCreated()
            .mock();

        Test.startTest();
        HttpResponse response = new TestApi().makeCallout('GET', '/api/v1');
        Test.stopTest();

        Assert.areEqual(201, response.getStatusCode());
    }

    @IsTest
    static void statusCodeAccepted() {
        new HttpMock()
            .get('/api/v1').statusCodeAccepted()
            .mock();

        Test.startTest();
        HttpResponse response = new TestApi().makeCallout('GET', '/api/v1');
        Test.stopTest();

        Assert.areEqual(202, response.getStatusCode());
    }

    @IsTest
    static void statusCodeNoContent() {
        new HttpMock()
            .get('/api/v1').statusCodeNoContent()
            .mock();

        Test.startTest();
        HttpResponse response = new TestApi().makeCallout('GET', '/api/v1');
        Test.stopTest();

        Assert.areEqual(204, response.getStatusCode());
    }

    @IsTest
    static void statusCodeBadRequest() {
        new HttpMock()
            .get('/api/v1').statusCodeBadRequest()
            .mock();

        Test.startTest();
        HttpResponse response = new TestApi().makeCallout('GET', '/api/v1');
        Test.stopTest();

        Assert.areEqual(400, response.getStatusCode());
    }

    @IsTest
    static void statusCodeUnauthorized() {
        new HttpMock()
            .get('/api/v1').statusCodeUnauthorized()
            .mock();

        Test.startTest();
        HttpResponse response = new TestApi().makeCallout('GET', '/api/v1');
        Test.stopTest();

        Assert.areEqual(401, response.getStatusCode());
    }

    @IsTest
    static void statusCodeForbidden() {
        new HttpMock()
            .get('/api/v1').statusCodeForbidden()
            .mock();

        Test.startTest();
        HttpResponse response = new TestApi().makeCallout('GET', '/api/v1');
        Test.stopTest();

        Assert.areEqual(403, response.getStatusCode());
    }

    @IsTest
    static void statusCodeNotFound() {
        new HttpMock()
            .get('/api/v1').statusCodeNotFound()
            .mock();

        Test.startTest();
        HttpResponse response = new TestApi().makeCallout('GET', '/api/v1');
        Test.stopTest();

        Assert.areEqual(404, response.getStatusCode());
    }

    @IsTest
    static void statusCodeMethodNotAllowed() {
        new HttpMock()
            .get('/api/v1').statusCodeMethodNotAllowed()
            .mock();

        Test.startTest();
        HttpResponse response = new TestApi().makeCallout('GET', '/api/v1');
        Test.stopTest();

        Assert.areEqual(405, response.getStatusCode());
    }

    @IsTest
    static void statusCodeInternalServerError() {
        new HttpMock()
            .get('/api/v1').statusCodeInternalServerError()
            .mock();

        Test.startTest();
        HttpResponse response = new TestApi().makeCallout('GET', '/api/v1');
        Test.stopTest();

        Assert.areEqual(500, response.getStatusCode());
    }

    @IsTest
    static void statusCodeNotImplemented() {
        new HttpMock()
            .get('/api/v1').statusCodeNotImplemented()
            .mock();

        Test.startTest();
        HttpResponse response = new TestApi().makeCallout('GET', '/api/v1');
        Test.stopTest();

        Assert.areEqual(501, response.getStatusCode());
    }

    @IsTest
    static void statusCodeBadGateway() {
        new HttpMock()
            .get('/api/v1').statusCodeBadGateway()
            .mock();

        Test.startTest();
        HttpResponse response = new TestApi().makeCallout('GET', '/api/v1');
        Test.stopTest();

        Assert.areEqual(502, response.getStatusCode());
    }

    @IsTest
    static void statusCodeServiceUnavailable() {
        new HttpMock()
            .get('/api/v1').statusCodeServiceUnavailable()
            .mock();

        Test.startTest();
        HttpResponse response = new TestApi().makeCallout('GET', '/api/v1');
        Test.stopTest();

        Assert.areEqual(503, response.getStatusCode());
    }

    @IsTest
    static void statusCodeGatewayTimeout() {
        new HttpMock()
            .get('/api/v1').statusCodeGatewayTimeout()
            .mock();

        Test.startTest();
        HttpResponse response = new TestApi().makeCallout('GET', '/api/v1');
        Test.stopTest();

        Assert.areEqual(504, response.getStatusCode());
    }

    @IsTest
    static void customStatusCode() {
        new HttpMock()
            .get('/api/v1').statusCode(403)
            .mock();

        Test.startTest();
        HttpResponse response = new TestApi().makeCallout('GET', '/api/v1');
        Test.stopTest();

        Assert.areEqual(403, response.getStatusCode());
    }

    @IsTest
    static void header() {
        new HttpMock()
            .get('/api/v1').header('Cache-Control', 'no-cache')
            .mock();

        Test.startTest();
        HttpResponse response = new TestApi().makeCallout('GET', '/api/v1');
        Test.stopTest();

        Assert.areEqual('no-cache', response.getHeader('Cache-Control'));
    }

    @IsTest
    static void multipleCalloutMock() {
        new HttpMock()
            .get('/api/v1').statusCodeOk()
            .get('/api/v2').statusCodeNotFound()
            .mock();

        Test.startTest();
        HttpResponse response1 = new TestApi().makeCallout('GET', '/api/v1');
        HttpResponse response2 = new TestApi().makeCallout('GET', '/api/v2');
        Test.stopTest();

        Assert.areEqual(200, response1.getStatusCode());
        Assert.areEqual(404, response2.getStatusCode());
    }

    @IsTest
    static void multipleCalloutMockWithSubpath() {
        new HttpMock()
            .get('/api/v1').statusCodeOk()
            .get('/api/v1/abc123').statusCodeNotFound()
            .mock();

        Test.startTest();
        HttpResponse response1 = new TestApi().makeCallout('GET', '/api/v1');
        HttpResponse response2 = new TestApi().makeCallout('GET', '/api/v1/abc123');
        Test.stopTest();

        Assert.areEqual(200, response1.getStatusCode());
        Assert.areEqual(404, response2.getStatusCode());
    }

    @IsTest
    static void multipleCalloutMockWithSubpathAndRandomMocking() {
        new HttpMock()
            .get('/api/v1').statusCodeNotFound()
            .get('/api/v1/abc123').statusCodeOk()
            .mock();

        Test.startTest();
        HttpResponse response1 = new TestApi().makeCallout('GET', '/api/v1/abc123');
        HttpResponse response2 = new TestApi().makeCallout('GET', '/api/v1');
        Test.stopTest();

        Assert.areEqual(200, response1.getStatusCode());
        Assert.areEqual(404, response2.getStatusCode());
    }

    @IsTest
    static void multipleCalloutToTheSameEndpoint() {
        new HttpMock()
            .get('/api/v1').statusCodeOk()
            .mock();

        Test.startTest();
        HttpResponse response1 = new TestApi().makeCallout('GET', '/api/v1');
        HttpResponse response2 = new TestApi().makeCallout('GET', '/api/v1');
        Test.stopTest();

        Assert.areEqual(200, response1.getStatusCode());
        Assert.areEqual(200, response2.getStatusCode());
    }

    @IsTest
    static void getRequestCount() {
        new HttpMock().get('/api/v1').statusCodeOk().mock();

        Test.startTest();
        new TestApi().makeCallout('GET', '/api/v1');
        new TestApi().makeCallout('GET', '/api/v1');
        Test.stopTest();

        Assert.areEqual(2, HttpMock.getRequestCount('GET', '/api/v1'));
    }

    @IsTest
    static void httpMethodNotMocked() {
        new HttpMock()
            .get('/api/v1').statusCodeOk()
            .mock();

        HttpMock.HttpMethodNotMockedException mockException = null;

        Test.startTest();
        try {
            new TestApi().makeCallout('POST', '/api/v1');
        } catch (HttpMock.HttpMethodNotMockedException e) {
            mockException = e;
        }
        Test.stopTest();

        Assert.isNotNull(mockException);
        Assert.areEqual('HTTP Method POST hasn\'t been mocked.', mockException.getMessage());
    }

    @IsTest
    static void httpEndpointNotMocked() {
        new HttpMock()
            .get('/api/v1').statusCodeOk()
            .mock();

        HttpMock.HttpEndpointNotMockedException mockException = null;

        Test.startTest();
        try {
            new TestApi().makeCallout('GET', '/api/v2');
        } catch (HttpMock.HttpEndpointNotMockedException e) {
            mockException = e;
        }
        Test.stopTest();

        Assert.isNotNull(mockException);
        Assert.areEqual('HTTP Endpoint /api/v2 hasn\'t been mocked.', mockException.getMessage());
    }

    private class TestApi {
        public HttpResponse makeCallout(String method, String endpoint) {
            HttpRequest request = new HttpRequest();

            request.setMethod(method);
            request.setEndpoint(endpoint);
            request.setHeader('Content-Type', 'application/json');
            request.setBody(JSON.serialize(new Map<String, String>{ 'name' => 'callout' }));

            return new Http().send(request);
        }
    }
}