/**
* This class is a custom OAuth-based authentication provider plug-in for single sign-on in to Salesforce.
*/
public with sharing class DocusignAuthProvider extends Auth.AuthProviderPluginClass {
    public static final String CUSTOM_METADATA_TYPE = 'DocuSign_Auth__mdt';
    public static final String AUTH_PROVIDER_NAME = 'DocuSignClientCredentials';
    public static final String USERNAME = 'DocuSign User';

    private IRefreshTokenGenerator generator = new DefaultRefreshTokenGenerator();

    @SuppressWarnings('PMD.EmptyStatementBlock')
    public DocusignAuthProvider() { }
    public DocusignAuthProvider(IRefreshTokenGenerator gen) {
        this.generator = gen;
    }

    public String getCustomMetadataType() {

        return CUSTOM_METADATA_TYPE;
    }

    @SuppressWarnings('PMD.ApexOpenRedirect')
    public PageReference initiate(Map<String, String> authProviderConfiguration, String stateToPropagate) {
        final String baseUrl = URL.getSalesforceBaseUrl().toExternalForm();
        final String url = baseUrl + '/services/authcallback/DocuSignClientCredentials' + '?state=' + stateToPropagate;

        return new PageReference(url);
    }

    public Auth.AuthProviderTokenResponse handleCallback(Map<String, String> config, Auth.AuthProviderCallbackState callbackState){
        final String accessToken = this.retrieveToken(config);
        final String refreshToken = this.generateRefreshToken();
        final String state = callbackState.queryParameters.get('state');

        return new Auth.AuthProviderTokenResponse(AUTH_PROVIDER_NAME, accessToken, refreshToken, state);
    }

    public Auth.UserData getUserInfo(Map<String, String> authProviderConfiguration, Auth.AuthProviderTokenResponse response) {

        return new Auth.UserData(
            null,
            null,
            null,
            null,
            null,
            null,
            USERNAME,
            null,
            AUTH_PROVIDER_NAME,
            null,
            new Map<String, String>()
       );
    }

    public override Auth.OAuthRefreshResult refresh(Map<String, String> config, String refreshToken) {
        final String newRefreshToken = this.generateRefreshToken();
        final String accessToken = this.retrieveToken(config);

        return new Auth.OAuthRefreshResult(accessToken, newRefreshToken);
    }

    private String retrieveToken(Map<String, String> config) {
        final String tokenEndpoint = config.get('Token_Endpoint__c');
        final String authRequestDomain = config.get('Request_Auth_Domain__c');
        final String alg = 'RS256';
        final String iss = config.get('Request_Integration_Key__c');
        final String pkey = config.get('Request_Private_Key__c');
        final String scope = config.get('Request_Scope__c');
        final String docuSignUsername = config.get('DocuSign_User_ID__c');

        DocuSignJWT jwtObject = new DocuSignJWT(alg, docuSignUsername, iss, pkey, scope, authRequestDomain);
        String requestBody = 'grant_type=urn:ietf:params:oauth:grant-type:jwt-bearer';
        requestBody += '&assertion=' + jwtObject.issue();

        HttpRequest req = new HttpRequest();
        req.setEndpoint(tokenEndpoint);
        req.setHeader('Content-Type', 'application/x-www-form-urlencoded');
        req.setHeader('Host', authRequestDomain);
        req.setMethod('POST');
        req.setBody(requestBody);

        Http h = new Http();
        HttpResponse res = h.send(req);

        String accessToken = this.getTokenFromHttpResponse(res);

        return accessToken;
    }

    /**
     * Get the access_token from Http response.
     */
    private String getTokenFromHttpResponse(HttpResponse res) {
        final Map<String, Object> data = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
        final String errorCode = (String) data.get('error');

        if (String.isNotEmpty(errorCode)) {
            String errorDescription = (String) data.get('error_description');
            String errorURI = (String) data.get('error_uri');
            throw new DocuSignAuthException(errorDescription).setDetails(
                errorCode,
                (String) data.get('error_description'),
                (String) data.get('error_uri')
            );
        } else {

            return (String) data.get('access_token');
        }
    }

    private String generateRefreshToken() {

        return this.generator.generate();
    }

    public class DocuSignAuthException extends Exception {
        public String error;
        public String errorDescription;
        public String errorURI;

        public DocuSignAuthException setDetails(String error, String errorDescription, String errorURI) {
            this.error = error;
            this.errorDescription = errorDescription;
            this.errorURI = errorURI;

            return this;
        }
    }

    /**
     * Interface to allow us to override refresh token generation when testing.
     */
    public interface IRefreshTokenGenerator {
        String generate();
    }

    /**
     * Default implementation for runtime.
     */
    public class DefaultRefreshTokenGenerator implements IRefreshTokenGenerator {
        public String generate() {
            final String refreshToken = EncodingUtil.base64Encode(Crypto.generateAesKey(128));

            return refreshToken;
        }
    }

}
