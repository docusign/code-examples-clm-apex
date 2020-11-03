# code-examples-clm-apex

## Introduction:
This repository will aid end users in connecting to the CLM API from Salesforce using [Apex](https://developer.salesforce.com/docs/atlas.en-us.apexcode.meta/apexcode/apex_intro_what_is_apex.htm) and The REST API.
We will be using JWT Authentication for authenticating to DocuSign REST API's and then performing a folder search using the REST API. This recipe will serve as a building block for users to customize and apply their own strategies while interacting with CLM from Salesforce using Apex.

## Pre-requisites:
- [Get a Salesforce Developer account](https://developer.salesforce.com/signup)

- [Get a DocuSign Developer account](https://go.docusign.com/o/sandbox)

##  Flow:
- Set up your DocuSign Integration Key.
- Find your DocuSign User ID and API Account ID.
- Installing the Github source.
- Set up Salesforce Custom Metadata.
- Set up Salesforce Remote Sites.
- Complete the Access Token Demo.

## Step-by-Step Walkthrough
  
  ### 1. Set up your DocuSign Integration key 
  - Login to your DocuSign Developer Account and select **Admin**. 
  - Under **Integrations**, select **API and Keys**. 
  - Select **Add Integration Key**
  - Provide an **App Description** and select **Save**
  - Click on the newly created Integrator Key. From the window that appears, note down the **Integrator Key**. This will be a unique GUID which will be associated with your Integration Key. You'll need to add this value to Salesforce later.
  - Select **Add URI** and add 'https://localhost'.
  - Select **Add RSA Key Pair** and note down the Private Key. 
  You'll need to add the Private Key to Salesforce later. **Do not copy the ----BEGIN RSA PRIVATE KEY---- and ----END RSA PRIVATE KEY---- lines**. 
  Select OK. 
  We have chosen to generate the RSA Key Pair since we will generating the JWT token to pass to the authentication key using the Private Key that we have noted down. This Private Key will be signed with the header and body of the request to complete the JWT token. Please see [JSON Web Token (JWT) Grant](https://developers.docusign.com/esign-rest-api/guides/authentication/oauth2-jsonwebtoken) for additional information on JWT and token construction.
  
  
 ![Integrator Key Screenshot](/images/IntegratorKey.PNG) 
 
 #### Impersonating user for API calls
 Since our recipe will be using the Integration key to make CLM API calls, we must ensure that a DocuSign user provides consent to the Integrator Key performing actions on their behalf. In this case the DocuSign user will be our Developer account user. For service integrations, you can set up a service user and grant consent on this user's behalf.
 
 To complete this step open the following URI in a browser:
 
 `https://account-d.docusign.com/oauth/auth?response_type=code&scope=signature%20impersonation%20spring_read%20spring_write&client_id=YOUR_KEY&redirect_uri=https://localhost`
 
 Make sure that:
 - For the client_id, you substitute the correct Integration Key for YOUR_INTEGRATION_KEY.
 - The value for the redirect_uri parameter matches the redirect URI configured for the Integration Key in your DocuSign Developer Account.
  
 When you open the URL in your browser, a consent screen displays. Select **Accept**.
 
 ![Consent Screenshot](/images/Consent.PNG) 
 
 After clicking Accept you will be redirected to the redirect URI you specified, indicating that consent was successfully granted.
 
  ### 2. Find your DocuSign User ID and API AccountID.
  - Log in to your DocuSign Developer Account and select **Admin**. 
  - Under **'Integrations'**, select **API and Keys**. 
  - Note down the **User ID** and **API Account ID**. You'll need to add these to your Salesforce Custom Metadata.  

### 3. Install the GitHub Source:
Deploy the files under the **src** folder to your Salesforce org. The src folder contains the a package.xml file which will help you to deploy the src.
You can use [Workbench](https://workbench.developerforce.com/login.php) for installation:
- Zip all the files such that folders and xml file present under the **src** folder are at the root of the zip file.
- Log in to Workbench
- Select **Migration -> Deploy**
- Select the zip file created in the earlier step. Check the **Single Package** checkbox and click on **Next**
- Select Deploy



### 4. Set up Salesforce Custom Metadata:
- Once the source files have been deployed successfully to your Salesforce org, navigate to **Setup -> Custom metadata types**.
- Click **Manage Records** under **DocuSignRESTSettings**
- Replace the values in the settings with the values for your DocuSign instance:
   - DSAccount  -> Your DocuSign API AccountID.
   - DSUserName -> Your DocuSign User ID.
   - RequestIntegratorKey -> Your Integration Key Id.
   - RequestPrivateKey -> Your Private Key.
   
### 5. Set up Salesforce Remote Sites: 
- Add 'https://account-d.docusign.com' as a Remote Site URL in your Salesforce instance. 
- Add the appropriate CLM REST API URL as a Remote Site URL in your Salesforce instance. You can find this in CLM Admin in the **Integrations** section of the **System Domains** page, or by consulting this chart: 

|                | **North America**               | **Europe**                      |
|----------------|---------------------------------|---------------------------------|
| **Test**       | https://apiuatna11.springcm.com | https://apiuateu11.springcm.com |
| **Production** | https://apina11.springcm.com    | https://apieu11.springcm.com    |


### 6. Complete the Access Token Demo: 
- Open the Developer Console
- Press **CTRL + E** (open execute Anonymous code window)
- Add the following line of code :
  `DocuSignRESTUtility.getAccessToken();`
- Highlight the added line of code and press **Execute Highlighted**  
- Navigate to the generated log file and choose the *Debug Only* level to monitor the logs generated.
- If the integration and setup are successfull you will notice a Status Code of 200 and the **ResponseAuthBody** parameter will also contain the `access_token`

![DeveloperConsole.JPG](/images/DeveloperConsole.JPG) 

### 7. Search CLM for a folder using Apex:
- Open the Developer Console
- Press CTRL + E (open execute Anonymous code window)
- Add the following line of code:
  `DocuSignRESTUtility.searchForFolder('SEARCH_QUERY');`
- Highlight the added line of code and press **Execute Highlighted**    

This example should search your CLM instance for folders matching the search query.

## License

The DocuSign Java Client is licensed under the following [License](LICENSE).
