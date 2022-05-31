/**
* This class is a custom OAuth-based authentication provider plug-in for single sign-on in to Salesforce.
*/
public with sharing class DocusignAuthProvider extends Auth.AuthProviderPluginClass {
    public static final String CUSTOM_METADATA_TYPE = 'DocuSign_Auth__mdt';
    public static final String AUTH_PROVIDER_NAME = 'DocuSignClientCredentials';
    public static final String USERNAME = 'DocuSign User';

    private IRefreshTokenGenerator generator = new DefaultRefreshTokenGenerator();

    public Boolean isProduction {
        get {
            if (isProduction == null) {
                Organization org = [SELECT Id, Name, IsSandbox FROM Organization];
                isProduction = !org.IsSandbox;
            }
            return isProduction;
        }
        set;
    }

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
        validateAuthProviderConfiguration(authProviderConfiguration);

        final String retURL = URL.getSalesforceBaseUrl().toExternalForm() + authProviderConfiguration.get('Callback_URL__c') + '&state=' + stateToPropagate;
        final String scope = authProviderConfiguration.get('Request_Scope__c');
        final String integrationKey = authProviderConfiguration.get('Request_Integration_Key__c');
        final String authDomain = authProviderConfiguration.get('Request_Auth_Domain__c');


        final String url = 'https://' + authDomain + '/oauth/auth?response_type=code&scope=' + EncodingUtil.urlEncode(scope, 'UTF-8') + '&client_id=' + integrationKey + '&redirect_uri=' +  retURL;

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
        validateAuthProviderConfiguration(config);

        // First check if the Auth Provider is intended to use in the sandbox we're in.  This is trying to prevent unintended requests after refreshing.
        final Boolean isProductionAuthProvider = Boolean.valueOf(config.get('Is_Production__c'));
        if (isProductionAuthProvider != isProduction) {
            throw new DocuSignAuthException('Auth Provider not valid for sandbox type.');
        }

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
        if (res?.getStatusCode() == 200) {
            Map<String, Object> data = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
            String accessToken = data.containsKey('access_token') ? (String) data.get('access_token') : '';
            return accessToken;
        } else {
            Map<String, Object> data = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());

            String errorCode = data.containsKey('error') ? (String) data.get('error') : '';
            String errorDescription = data.containsKey('error_description') ? (String) data.get('error_description') : '';

            throw new DocuSignAuthException(errorDescription).setDetails(
                errorCode,
                errorDescription
            );
        }
    }

    private String generateRefreshToken() {

        return this.generator.generate();
    }

    private void validateAuthProviderConfiguration(Map<String, String> authProviderConfiguration) {
        List<String> requiredConfigAttributes = new List<String> {
            'Callback_URL__c',
            'DocuSign_User_ID__c',
            'Is_Production__c',
            'Request_Auth_Domain__c',
            'Request_Integration_Key__c',
            'Request_Private_Key__c',
            'Request_Scope__c',
            'Token_Endpoint__c'
        };

        for (String attribute : requiredConfigAttributes) {
            if (!authProviderConfiguration.containsKey(attribute) || String.isBlank(authProviderConfiguration.get(attribute))) {
                throw new DocuSignAuthException('Missing ' + attribute + ' attribute from Auth Provider Config.');
            }
        }
    }

    public class DocuSignAuthException extends Exception {
        public String error;
        public String errorDescription;
        public String errorURI;

        public DocuSignAuthException setDetails(String error, String errorDescription) {
            this.error = error;
            this.errorDescription = errorDescription;

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
