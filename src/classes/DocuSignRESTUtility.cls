/* This class is responsible for searching for folders by making REST Callouts to DocuSign CLM */
/* You can extend the searchForFolder method by invoking it from triggers / scheduled apex / batch jobs */
/* You can also create invocable actions by referencing the searchForFolder method and use it in Process Builders */

public class DocuSignRestUtility {

    //Get Rest Configuration Setings from Custom Metadata provided as a part of the installation source 
    private static Map<String, DocuSignRestSettings__mdt> settingsMap { 
        //Getter Method
        get {
            //populate only if settingsMap is null
            if (settingsMap == null) {
                settingsMap = new Map<String, DocuSignRestSettings__mdt>();
                //Query the Custom Metadata and add it to the Map
                //Query against Custom Metadata does not count against the SOQL query Limit
                for (DocuSignRestSettings__mdt setting : [Select DeveloperName,MasterLabel, Value__c from DocuSignRestSettings__mdt]) {
                    settingsMap.put(setting.MasterLabel, setting);
                }
            }
            return settingsMap;
        }
        //Blank Setter Method
        set {
        }
    }

    //This method will call the DocuSignJWT class to obtain an access token from DocuSign
    public static String getAccessToken() {
        String access_token = null;
        
        //Instantiate a request object
        HttpRequest req = new HttpRequest();
        //set the request METHOD
        req.setMethod('POST');
        
        //set the request endpoint
        String authendpoint = settingsMap.get('RequestAuthEndpoint').Value__c;
        System.Debug(LoggingLevel.INFO, '**RequestAuthEndpoint' + authendpoint);
        req.setEndPoint(authendpoint);

        //set the request headers
        //1. Content -type
        String authRequestContentType = settingsMap.get('RequestAuthContentType').Value__c;
        System.Debug(LoggingLevel.INFO, '**authRequestContentType ' + authRequestContentType);
        req.setHeader('Content-type', authRequestContentType);

        //2. Host
        String authRequestDomain = settingsMap.get('RequestAuthDomain').Value__c;
        System.Debug(LoggingLevel.INFO, '**authRequestDomain ' + authRequestDomain);
        req.setHeader('Host', authRequestDomain);

        //Body of the request
        String alg = 'RS256';
        String iss = settingsMap.get('RequestIntegratorKey').Value__c;
        String pkey = settingsMap.get('RequestPrivateKey').Value__c;
        String scope = settingsMap.get('RequestScope').Value__c;
        DocuSignJWT jwtObject = new DocuSignJWT(alg, settingsMap.get('DSUserName').Value__c, iss, pkey, scope, authRequestDomain);
		
	//Set the request body	
        String requestBody = settingsMap.get('RequestAuthBody').Value__c + jwtObject .issue();
        System.Debug(LoggingLevel.INFO, '**RequestAuthBody' + requestBody);
        req.setBody(requestBody);

        //call the service
        Http http = new Http();
        HTTPResponse res = http.send(req);

        System.Debug(LoggingLevel.INFO, '**ResponseAuthBody' + res.getbody());
        System.Debug(LoggingLevel.INFO, '**ResponseAuth' + res);
		
	//Obtain the access token from the Response
        if (res.getStatusCode() == 200) {
            System.JSONParser parser = System.JSON.createParser(res.getBody());
            while (parser.nextToken() != null) {
                if ((parser.getCurrentToken() == JSONToken.FIELD_NAME) && (parser.getText() == 'access_token')) {
                    parser.nextToken();
                    access_token = parser.getText();
                    break;
                }
            }
        }

        return access_token;

    }
    
    @future(callout=true)
    public static void searchForFolder(string query) {
        //Get the access token
        String accessToken = getAccessToken();
        System.Debug(LoggingLevel.INFO, '***accessToken ' + accessToken);

        //Call CLM API if a non-empty access token is returned
        if (!String.isEmpty(accessToken)) {
            //instantiate an Http instance  
            Http httpProtocol = new Http();

            //instantiate an HttpRequest instance  
            HttpRequest request = new HttpRequest();

            //Set the request parameters 
            // Request endpoint for folder search call
            String endpoint = settingsMap.get('CLMv2ApiEndpoint').Value__c + settingsMap.get('DSAccountID').Value__c + '/folders/search?search=' + query;
            System.Debug(LoggingLevel.INFO, '***endpoint ' + endpoint);
            request.setEndPoint(endpoint);

            //set the GET method
            request.setMethod('GET');

            //set Authentication Header
            request.setHeader('grant_type', 'Bearer');
            request.setHeader('Authorization', 'Bearer ' + accessToken);

            //set Accept Header
            request.setHeader('Accept', 'application/json');

            //set Content Type Header
            request.setHeader('Content-type', 'application/json');

            //Make the request and capture the response
            HttpResponse response = httpProtocol.send(request);
            System.Debug(LoggingLevel.INFO, '***response.getBody() ' + response.getBody());
            System.debug(LoggingLevel.INFO, '***response.getStatus() ' + response.getStatus());
			
	    //Parse the response
            String responseStatus = response.getStatus();
            if (responseStatus.equals('Created')) {
                DocuSignRESTUtility.FolderSearchResponse responseObject = new DocuSignRESTUtility.FolderSearchResponse();
                responseObject = (DocuSignRESTUtility.FolderSearchResponse)System.JSON.deserialize(response.getBody(), DocuSignRESTUtility.FolderSearchResponse.class);
                System.Debug(LoggingLevel.INFO, '***responseObject ' + responseObject);
            }
        }
    }

    //wrapper class for Folder Search Response
    public class FolderSearchResponse
    {
        public FolderItem[] Items { get; set; }
        public String Href { get; set; }
        public long Offset { get; set; }
        public String First { get; set; }
        public String Last { get; set; }
        public long Total { get; set; }
    }

    public class FolderItem
    {
        public String Name { get; set; }
        public DateTime CreatedDate { get; set; }
        public String CreatedBy { get; set; }
        public DateTime UpdatedDate { get; set; }
        public String UpdatedBy { get; set; }
        public String Description { get; set; }
        public Documents ParentFolder { get; set; }
        public String BrowseDocumentsUrl { get; set; }
        public AccessLevel AccessLevel { get; set; }
        public Documents Documents { get; set; }
        public Documents Folders { get; set; }
        public Documents ShareLinks { get; set; }
        public String CreateDocumentHref { get; set; }
        public String Href { get; set; }
    }

    public class AccessLevel
    {
        public boolean See { get; set; }
        public boolean Read { get; set; }
        public boolean Write { get; set; }
        public boolean Move { get; set; }
        public boolean Create { get; set; }
        public boolean SetAccess { get; set; }
    }

    public class Documents
    {
        public String Href { get; set; }
    }

}
