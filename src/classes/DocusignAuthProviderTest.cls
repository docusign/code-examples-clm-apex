@isTest
public class DocusignAuthProviderTest {

    private static final String TOKEN_ENDPOINT = 'dummy_token_endpoint';
    private static final String ACCESS_TOKEN = 'dummy_access_token';
    private static final String REFRESH_TOKEN = 'dummy_refresh_token';

    @isTest
    public static void testGetMetadataType() {
        DocusignAuthProvider instance = new DocusignAuthProvider();
        System.assertEquals(DocusignAuthProvider.CUSTOM_METADATA_TYPE, instance.getCustomMetadataType(), 'Incorrect metadata type returned');
    }

    @isTest
    public static void testInitiate() {
        DocusignAuthProvider instance = new DocusignAuthProvider();
        final String state = 'randomState';

        Map<String, String> defaultConfig = getDefaultConfig();
        PageReference ref = instance.initiate(defaultConfig, state);

        String expectedURL = String.format(
            'https://{0}/oauth/auth?client_id={1}&redirect_uri={2}{3}&response_type=code&scope={4}&state={5}',
            new List<String>{
                defaultConfig.get('Request_Auth_Domain__c'),
                defaultConfig.get('Request_Integration_Key__c'),
                EncodingUtil.urlEncode(URL.getSalesforceBaseUrl().toExternalForm(), 'UTF-8'),
                defaultConfig.get('Callback_URL__c'),
                EncodingUtil.urlEncode(defaultConfig.get('Request_Scope__c'), 'UTF-8'),
                state
            }
        );
        System.assertEquals(expectedURL, ref.getUrl(), 'Incorrect URL');
    }

    @isTest
    public static void testHandleCallback_Success() {
        Map<String, String> config = getDefaultConfig();

        final String mockResponse = '{"access_token": "' + ACCESS_TOKEN + '"}';

        final TokenEndpointHttpCalloutMockImpl httpMock = new TokenEndpointHttpCalloutMockImpl(mockResponse);
        Test.setMock(HttpCalloutMock.class, httpMock);

        DocusignAuthProvider instance = new DocusignAuthProvider(new StaticRefreshTokenGenerator());
        final Map<String, String> queryArgs = new Map<String, String>();
        queryArgs.put('state', 'randomState');
        Auth.AuthProviderCallbackState callbackState = new Auth.AuthProviderCallbackState(new Map<String, String>(), '', queryArgs);

        // call
        Auth.AuthProviderTokenResponse response = instance.handleCallback(config, callbackState);

        // assert
        httpMock.assertUrl(TOKEN_ENDPOINT);
        httpMock.assertContentType('application/x-www-form-urlencoded');
        httpMock.assertMethod('POST');
        httpMock.assertBody('grant_type=urn:ietf:params:oauth:grant-type:jwt-bearer&assertion=');
        System.assertEquals(DocusignAuthProvider.AUTH_PROVIDER_NAME, response.provider, 'Incorrect provider');
        System.assertEquals(ACCESS_TOKEN, response.oauthToken, 'Incorrect token');
        System.assertEquals(REFRESH_TOKEN, response.oauthSecretOrRefreshToken, 'Incorrect refresh token');
        System.assertEquals('randomState', response.state, 'Incorrect state');
    }

    @isTest
    public static void testHandleCallback_Error() {
        String errorCode = 'SomeErrorCode';
        String errorDescription = 'Some description';

        final Map<String, String> config = getDefaultConfig();

        final Map<String, String> mockResponse = new Map <String, String>{
            'error' => errorCode,
            'error_description' => errorDescription,
            'error_uri' => 'some_error_uri'
        };
        final TokenEndpointHttpCalloutMockImpl httpMock = new TokenEndpointHttpCalloutMockImpl(JSON.serialize(mockResponse));
        httpMock.setResponseStatus(400);

        Test.setMock(HttpCalloutMock.class, httpMock);

        final Map<String, String> queryArgs = new Map<String, String>();
        Auth.AuthProviderCallbackState callbackState = new Auth.AuthProviderCallbackState(new Map<String, String>(), '', queryArgs);

        try {
            DocusignAuthProvider instance = new DocusignAuthProvider();
            Auth.AuthProviderTokenResponse response = instance.handleCallback(config, callbackState);
            System.assert(false, 'Expected method to throw exception');
        } catch (DocusignAuthProvider.DocuSignAuthException e) {
            httpMock.assertUrl(TOKEN_ENDPOINT);
            httpMock.assertMethod('POST');
            System.assertEquals(errorCode, e.error, 'Incorrect error code');
            System.assertEquals(errorDescription, e.getMessage(), 'Incorrect description');
        }
    }

    @isTest
    public static void testGetUserInfo() {
        DocusignAuthProvider instance = new DocusignAuthProvider();
        Auth.UserData r = instance.getUserInfo(null, null);
        System.assertEquals(DocusignAuthProvider.USERNAME, r.username, 'Incorrect username');
        System.assertEquals(DocusignAuthProvider.AUTH_PROVIDER_NAME, r.provider, 'Incorrect auth provider name');
    }

    @isTest
    public static void testRefresh() {
        Map<String, String> config = getDefaultConfig();

        final String mockResponse = '{"access_token": "' + ACCESS_TOKEN + '"}';

        final TokenEndpointHttpCalloutMockImpl httpMock = new TokenEndpointHttpCalloutMockImpl(mockResponse);
        Test.setMock(HttpCalloutMock.class, httpMock);

        // call
        DocusignAuthProvider instance = new DocusignAuthProvider(
            new StaticRefreshTokenGenerator()
        );
        Auth.OAuthRefreshResult response = instance.refresh(config, null);

        // assert
        httpMock.assertUrl(TOKEN_ENDPOINT);
        httpMock.assertContentType('application/x-www-form-urlencoded');
        httpMock.assertMethod('POST');
        System.assertEquals(ACCESS_TOKEN, response.accessToken, 'Incorrect access token');
        System.assertEquals(REFRESH_TOKEN, response.refreshToken, 'Incorrect refresh token');
        System.assert(null == response.error, 'Response error not null');
    }

    private static Map<String, String> getDefaultConfig() {
        Map<String, String> config = new Map<String, String>();
        config.put('Is_Production__c', String.valueOf(![SELECT Id, Name, IsSandbox FROM Organization].IsSandbox));
        config.put('Token_Endpoint__c', TOKEN_ENDPOINT);
        config.put('Request_Auth_Domain__c', 'authDomain');
        config.put('Request_Integration_Key__c', 'integrationKey');
        config.put('Request_Private_Key__c', 'MIIEpAIBAAKCAQEAxCg+YPlTDjljhg7YQs4n6jMAth0raDV6rnQ0z5MC+Fhr/k0W2pKZcqZ7Rp260f36CgbG2lzMZacBhZeY2JWQUjfXG5UuRi4w259uGTVP+iS/n7LRABeFneYp663TOH2NE7ELmK2ycks12AOW5WIayJbADzKEiwgU1ulYXioZ5jXiUdE92mciu1HwOV/EUM6EPraaCG9Ufv+cL/VcEp6qW+IB3J31mYF+jfDo4+wMkwJLu+qgRcV+Zfas0GFuqlJoBYu7gAce/2+TtC1jKpOTM9vKk4uNqiwB5BsMIi1PIpLR2hWnpF6gr9y1lG0ChGUTXpbM9wvl22Znst/QslFjewIDAQABAoIBAAz7PNNL0VIp80Hj8sCCNC115zK4dJyo5D2Sx8LLz96B4BqZ+JXJ5MAZprW9qoLdc//YJ4nyzs+CPMHU16nP/BdijzruXHvmOYWGLT+t1Bv/hypicNS4uclKeiKZBA4Mbr9m3c6+AlAU59fitzZUtFNY5qhj9TGVIZ43Z65Kgde0i3ySxO8syVKYZ5baXwRWTKeC5m4/XtCI4fptTZIGKV/wPpGdh0bX4tLqk+LFU7wSCQEcS5UIjIWalJyEKJTIw0Z9gNMGxUryDC1ocGHjXuUEQQ5g6MCfEPJiTpPI9lrZMjnLZ1IadtGVF8uAaiD4FSvOWd5JXOj1eMYbruDoKwECgYEA7W97uoWubtVZ/TVgagmVCeioTCAGxR/M6cNtUFm3wduJqVIejyKPj+lpxNaFPszmvPK941pR6+GRvE1bswzn5nbUqwvcUVyfHt68U1GLutgVNF9beMPP8eqTH/QLa4xgtgo1jNeM0dkAsvIhQ4ImI1g4mADEKVYprYOiDoW5ljECgYEA036Ia/GGfDcVxXVYQISzlZVKIBqortABGj9gpqTIJkT0ZRz5pcBSBxlh1xr00mnSrJ5dKkHBU3x8wYwmsDn455jJp8virDX6MlplqDspZIL8IGc0ULYjcNM5wBu+ZfV4xirQDS+bP4YVrB5nnGOXSAeCXcUMUgDhbEM3H4ipLWsCgYA24jc6hV4t1nlns2fm+vINiU8l0Z1fAZvPSVJCaYq1b/bhQc84jOecf3roeiHww1JuyLmmDSG0ob6bRVJ2D/ym5D8CjspNsFhDvX7Qz5+5/+re4U/2mWS+6dc6YqIlKRzN14xLUyQE+eFUe+2+eh4wu1rRoBO37mfR6QST0Mt2cQKBgQC2k4Uxqk9u7B7fV23YRLbDax2SmXEFeIt7HTtSoO4oG17f6yOY823cswzDpYG0I6a7XfsPf7RlXhJVA6hiealmRX/QWzJTeEWFMoSPtoMFQg5l6rI++v2daLtyHIFBg6e/azYwK+jZ7ebHr3fCijcO92yThogcQqZXz67GijOCAQKBgQDD8avFNgz6Q9Tfec1ucybjQRtdhAGBOTCJjAyC69ZGwdkMOX7bw8ZcYS3anYE7FeAlCoFxQX9lLQsP87kdLRD4x/CVNHXk3p2AzmeNu4Dn7x0ppYPU/qObhc0h4f5QvNygteP2/t5L29m4fWZWs/jwi1o67ZKXwgnkp5O8CgN2dQ==');
        config.put('Request_Scope__c', 'scope1,scope2');
        config.put('DocuSign_User_ID__c', 'docuSignUserID');
        config.put('Callback_URL__c', 'callbackURL');

        return config;
    }

    private class TokenEndpointHttpCalloutMockImpl implements HttpCalloutMock {
        private String callUrl;
        private String callMethod;
        private String callBody;
        private Map<String, String> callHeaders = new Map<String, String>();
        private String responseBody;
        private String responseContentType = 'application/json';
        private Integer responseStatus = 200;

        public TokenEndpointHttpCalloutMockImpl(String response) {
            this.responseBody = response;
        }

        public TokenEndpointHttpCalloutMockImpl(String response, String contentType) {
            this(response);
            this.responseContentType = contentType;
        }

        public TokenEndpointHttpCalloutMockImpl setResponseStatus(Integer status) {
            this.responseStatus = status;

            return this;
        }

        public void assertMethod(String method) {
            if (String.isEmpty(this.callMethod)) {
                System.assert(false, 'Method never set');
            }
            System.assertEquals(method, this.callMethod, 'Incorrect call method');
        }

        public void assertUrl(String url) {
            if (String.isEmpty(this.callUrl)) {
                System.assert(false, 'URL never called');
            }
            System.assertEquals(url, this.callUrl, 'Incorrect call URL');
        }

        public void assertBody(String body) {
            if (String.isEmpty(this.callBody)) {
                System.assert(false, 'URL never called');
            }
            System.assert(this.callBody.contains(body), 'Incorrect body');
        }

        public void assertContentType(String value) {
            this.assertHeader('Content-Type', value);
        }

        public void assertHeader(String key, String value) {
            if (this.callHeaders.size() == 0) {
                System.assert(false, 'No headers');
            }
            if (String.isEmpty(key)) {
                System.assert(false, 'Must supply header name');
            }
            String v = this.callHeaders.get(key.toLowerCase());
            if (String.isEmpty(v)) {
                System.assert(false, 'Header not set');
            }
            System.assertEquals(value, v, 'Incorrect value');
        }

        public HTTPResponse respond(HTTPRequest req) {
            this.callUrl = req.getEndpoint();
            this.callMethod = req.getMethod();
            this.callBody = req.getBody();
            this.callHeaders.put('content-type', req.getHeader('Content-Type'));
            this.callHeaders.put('accept', req.getHeader('Accept'));

            // Create a fake response
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', this.responseContentType);
            res.setBody(this.responseBody);
            res.setStatusCode(this.responseStatus);

            return res;
        }
    }

    private class StaticRefreshTokenGenerator implements DocusignAuthProvider.IRefreshTokenGenerator {
        public String generate() {
            return REFRESH_TOKEN;
        }
    }
}