/**
 * Copyright (c) 2024 Beyond The Cloud Sp. z o.o. (BeyondTheCloud.Dev)
 * Licensed under the MIT License (https://github.com/beyond-the-cloud-dev/http-mock-lib/blob/main/LICENSE)
**/
@IsTest
public class HttpMock implements HttpMockLib, HttpCalloutMock {
    /*
        new HttpMock()
            .get('/api/v1/authorize').body('{ "token": "aZ3Xb7Qk" }').statusCodeOk()
            .post('/api/v1/create').body('{ "success": true, "message": null }').statusCodeOk()
            .mock();
    */
    public interface HttpMockLib {
        HttpMock get(String endpointToMock);
        HttpMock post(String endpointToMock);
        HttpMock put(String endpointToMock);
        HttpMock patch(String endpointToMock);
        HttpMock deletex(String endpointToMock);
        HttpMock trace(String endpointToMock);
        HttpMock head(String endpointToMock);
        // Body
        HttpMock body(Object body);
        HttpMock body(String body);
        HttpMock body(Blob body);
        // Content-Type
        HttpMock contentTypePlainText(); // text/plain
        HttpMock contentTypeHtml(); // text/html
        HttpMock contentTypeCsv(); // text/csv
        HttpMock contentTypeJson(); // application/json
        HttpMock contentTypeXml(); // application/xml
        HttpMock contentTypePdf(); // application/pdf
        HttpMock contentTypeFormUrlencoded(); // application/x-www-form-urlencoded
        HttpMock contentType(String contentType);
        // Status Code
        HttpMock statusCodeOk(); // 200
        HttpMock statusCodeCreated(); // 201
        HttpMock statusCodeAccepted(); // 202
        HttpMock statusCodeNoContent(); // 204
        HttpMock statusCodeBadRequest(); // 400
        HttpMock statusCodeUnauthorized(); // 401
        HttpMock statusCodeForbidden(); // 403
        HttpMock statusCodeNotFound(); // 404
        HttpMock statusCodeMethodNotAllowed(); // 405
        HttpMock statusCodeInternalServerError(); // 500
        HttpMock statusCodeNotImplemented(); // 501
        HttpMock statusCodeBadGateway(); // 502
        HttpMock statusCodeServiceUnavailable(); // 503
        HttpMock statusCodeGatewayTimeout(); // 504
        HttpMock statusCode(Integer statusCode);
        // Headers
        HttpMock header(String key, String value);
        // Mock
        void mock();
    }

    public static Integer getRequestCount(String httpMethod, String endpoint) {
        if (!requestCountByMethodAndEndpoint.containsKey(httpMethod)) {
            return 0;
        }

        return requestCountByMethodAndEndpoint.get(httpMethod).get(endpoint) ?? 0;
    }

    // Implementation

    private static Map<String, Map<String, HttpResponse>> mocks = new Map<String, Map<String, HttpResponse>>();
    private static Map<String, Map<String, Integer>> requestCountByMethodAndEndpoint = new Map<String, Map<String, Integer>>();

    private HttpResponse workingHttpResponse = null;

    public HttpMock get(String endpointToMock) {
        return add('GET', endpointToMock);
    }

    public HttpMock post(String endpointToMock) {
        return add('POST', endpointToMock);
    }

    public HttpMock put(String endpointToMock) {
        return add('PUT', endpointToMock);
    }

    public HttpMock patch(String endpointToMock) {
        return add('PATCH', endpointToMock);
    }

    public HttpMock deletex(String endpointToMock) {
        return add('DELETE', endpointToMock);
    }

    public HttpMock trace(String endpointToMock) {
        return add('TRACE', endpointToMock);
    }

    public HttpMock head(String endpointToMock) {
        return add('HEAD', endpointToMock);
    }

    private HttpMock add(String httpMethod, String endpointToMock) {
        if (!mocks.containsKey(httpMethod)) {
            mocks.put(httpMethod, new Map<String, HttpResponse>());
        }

        this.workingHttpResponse = new HttpResponse();

        body('{}');
        contentTypeJson();
        statusCodeOk();

        mocks.get(httpMethod).put(endpointToMock, this.workingHttpResponse);

        return this;
    }

    public HttpMock body(Object body) {
        return body(JSON.serialize(body));
    }

    public HttpMock body(String body) {
        this.workingHttpResponse.setBody(body);
        return this;
    }

    public HttpMock body(Blob body) {
        this.workingHttpResponse.setBodyAsBlob(body);
        return this;
    }

    public HttpMock contentTypePlainText() {
        return contentType('text/plain');
    }

    public HttpMock contentTypeHtml() {
        return contentType('text/html');
    }

    public HttpMock contentTypeCsv() {
        return contentType('text/csv');
    }

    public HttpMock contentTypeJson() {
        return contentType('application/json');
    }

    public HttpMock contentTypePdf() {
        return contentType('application/pdf');
    }

    public HttpMock contentTypeXml() {
        return contentType('application/xml');
    }

    public HttpMock contentTypeFormUrlencoded() {
        return contentType('application/x-www-form-urlencoded');
    }

    public HttpMock contentType(String contentType) {
        return header('Content-Type', contentType);
    }

    public HttpMock header(String key, String value) {
        this.workingHttpResponse.setHeader(key, value);
        return this;
    }

    public HttpMock statusCodeOk() {
        return statusCode(200);
    }

    public HttpMock statusCodeCreated() {
        return statusCode(201);
    }

    public HttpMock statusCodeAccepted() {
        return statusCode(202);
    }

    public HttpMock statusCodeNoContent() {
        return statusCode(204);
    }

    public HttpMock statusCodeBadRequest() {
        return statusCode(400);
    }

    public HttpMock statusCodeUnauthorized() {
        return statusCode(401);
    }

    public HttpMock statusCodeForbidden() {
        return statusCode(403);
    }

    public HttpMock statusCodeNotFound() {
        return statusCode(404);
    }

    public HttpMock statusCodeMethodNotAllowed() {
        return statusCode(405);
    }

    public HttpMock statusCodeInternalServerError() {
        return statusCode(500);
    }

    public HttpMock statusCodeNotImplemented() {
        return statusCode(501);
    }

    public HttpMock statusCodeBadGateway() {
        return statusCode(502);
    }

    public HttpMock statusCodeServiceUnavailable() {
        return statusCode(503);
    }

    public HttpMock statusCodeGatewayTimeout() {
        return statusCode(504);
    }

    public HttpMock statusCode(Integer statusCode) {
        this.workingHttpResponse.setStatusCode(statusCode);
        return this;
    }

    public void mock() {
        Test.setMock(HttpCalloutMock.class, this);
    }

    public HttpResponse respond(HttpRequest request) {
        String closestMatchingMockedEndpoint = findClosestMatchingMockedEndpoint(request);

        if (String.isBlank(closestMatchingMockedEndpoint)) {
            throw new HttpEndpointNotMockedException('HTTP Endpoint ' + request.getEndpoint() + ' hasn\'t been mocked.');
        }

        String requestMethod = request.getMethod();

        incrementRequestCount(requestMethod, closestMatchingMockedEndpoint);
        return mocks.get(requestMethod).get(closestMatchingMockedEndpoint);
    }

    private String findClosestMatchingMockedEndpoint(HttpRequest httpRequest) {
        String httpRequestMethod = httpRequest.getMethod();

        if (!mocks.containsKey(httpRequestMethod)) {
            throw new HttpMethodNotMockedException('HTTP Method ' + httpRequestMethod + ' hasn\'t been mocked.');
        }

        String httpRequestEndpoint = httpRequest.getEndpoint();
        return findClosestMatchingMockedEndpoint(httpRequestEndpoint, mocks.get(httpRequestMethod).keySet());
    }

    public static String findClosestMatchingMockedEndpoint(String requestEndpoint, Set<String> mockedEndpoints) {
        String closestMatchingMockedEndpoint = null;
        Integer maxMatchLength = 0;

        for (String mockedEndpoint : mockedEndpoints) {
            if (requestEndpoint.contains(mockedEndpoint) && mockedEndpoint.length() > maxMatchLength) {
                closestMatchingMockedEndpoint = mockedEndpoint;
                maxMatchLength = mockedEndpoint.length();
            }
        }

        return closestMatchingMockedEndpoint;
    }

    private void incrementRequestCount(String httpMethod, String endpoint) {
        if (!requestCountByMethodAndEndpoint.containsKey(httpMethod)) {
            requestCountByMethodAndEndpoint.put(httpMethod, new Map<String, Integer>());
        }

        Integer currentCount = requestCountByMethodAndEndpoint.get(httpMethod).get(endpoint) ?? 0;
        requestCountByMethodAndEndpoint.get(httpMethod).put(endpoint, currentCount + 1);
    }

    public class HttpMethodNotMockedException extends Exception {}
    public class HttpEndpointNotMockedException extends Exception {}
}