/* This class is responsible for searching for folders by making REST Callouts to DocuSign CLM */
/* You can extend the searchForFolder method by invoking it from triggers / scheduled apex / batch jobs */
/* You can also create invocable actions by referencing the searchForFolder method and use it in Process Builders */

public class DocuSignRESTUtility {

    //Get Rest Configuration Settings from Custom Metadata provided as a part of the installation source
    private static Map<String, DocuSignRESTSettings__mdt> settingsMap {
        //Getter Method
        get {
            //populate only if settingsMap is null
            if (settingsMap == null) {
                settingsMap = new Map<String, DocuSignRESTSettings__mdt>();
                //Query the Custom Metadata and add it to the Map
                //Query against Custom Metadata does not count against the SOQL query Limit
                for (DocuSignRESTSettings__mdt setting : [Select DeveloperName,MasterLabel, Value__c from DocuSignRESTSettings__mdt]) {
                    settingsMap.put(setting.MasterLabel, setting);
                }
            }
            return settingsMap;
        }
        //Blank Setter Method
        set {
        }
    }

    @future(callout=true)
    public static void searchForFolder(string query) {
        //instantiate an Http instance
        Http httpProtocol = new Http();

        //instantiate an HttpRequest instance
        HttpRequest request = new HttpRequest();

        // Set the request parameters
        // Request endpoint for folder search call
        String endpoint = settingsMap.get('DSAccountID').Value__c + '/folders/search?search=' + query;
        System.debug(LoggingLevel.INFO, '***endpoint ' + endpoint);
        request.setEndpoint('callout:Docusign' + endpoint);

        //set the POST method
        request.setMethod('POST');

        //set Accept Header
        request.setHeader('Accept', 'application/json');

        //set Content Type Header
        request.setHeader('Content-type', 'application/json');

        //set Empty Body - Check out https://developers.docusign.com/docs/clm-api/reference/Objects/Folders/Search/ for more details if required
        request.setBody('');

        //Make the request and capture the response
        HttpResponse response = httpProtocol.send(request);
        System.debug(LoggingLevel.INFO, '***response.getBody() ' + response.getBody());
        System.debug(LoggingLevel.INFO, '***response.getStatus() ' + response.getStatus());

        //Parse the response
        String responseStatus = response.getStatus();
        if (responseStatus.equals('Created')) {
            DocuSignRESTUtility.FolderSearchResponse responseObject = new DocuSignRESTUtility.FolderSearchResponse();
            responseObject = (DocuSignRESTUtility.FolderSearchResponse)System.JSON.deserialize(response.getBody(), DocuSignRESTUtility.FolderSearchResponse.class);
            System.debug(LoggingLevel.INFO, '***responseObject ' + responseObject);
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
