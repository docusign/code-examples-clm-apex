# code-examples-clm-apex

## Introduction:
This repository will aid end users in connecting to the CLM API from Salesforce using Apex and REST API.
We will be using JWT Authentication for authenticating to DocuSign REST API's and then performing a folder search using REST API. This recipe will serve as a building block for users to customize and apply their own strategies while interacting with CLM from Salesforce using Apex.

## Pre-requisites:
- Get a Salesforce Developer account
https://developer.salesforce.com/signup

- Get a DocuSign Developer account
https://go.docusign.com/o/sandbox

##  Building Blocks:
- DocuSign Integrator Key setup.
- Installing Github source.
- Salesforce Remote Sites and Custom Metadata types setup.
- Developer Console demo.

## Step by Step Walkthrough
  
  ### 1. DocuSign Integrator key setup 
  - Login to your DocuSign Developer Sandbox and click on **Go to Admin** . 
  - Select **API and Keys** link which should be found under **'Integrations'**. 
  - Click on **Add Integrator Key**
  - Provide an App Description and click **Save**
  - Click on the newly created Integrator Key and from the resulting pop-up note down the **Integrator Key** . This will be a unique GUID which will be associated with your Integrator key.This needs to be updated in Salesforce.
  - Click on **Add URI** and add 'https://localhost.com'.
  - Click on **Add RSA Key Pair** and note down the Private Key. 
  The Private key will be updated in Salesforce. **Do not copy the ----BEGIN RSA PRIVATE KEY---- and ----END RSA PRIVATE KEY---- lines**. 
  Click OK. 
  We have chosen to generate the RSA Key Pair since we will generating the JWT token to pass to the authentication key using the Private Key that we have noted down. This Private Key will be signed with Header and Body of the Request to complete the JWT token. Please refer the [JSON Web Token Bearer Grant](https://developers.docusign.com/esign-rest-api/guides/authentication/oauth2-jsonwebtoken) link for additional information on JWT and token construction.
  
  
 ![Integrator Key Screenshot](/images/IntegratorKey.JPG) 
 
 #### Impersonating user for API calls.
 Since our recipe will be using the Integrator key to make CLM API calls, we must ensure that a DocuSign user provides consent to the Integrator key. In this case the DocuSign user will be our Sandbox user. In case of service integrations we can setup a service user and grant consent on this user's behalf.
 
 To complete this step open the following URI in a browser:
 
 `https://account-d.docusign.com/oauth/auth?
  response_type=code&scope=signature%20impersonation%20spring_read%20spring_write&client_id=YOUR_KEY&redirect_uri=https://localhost.com`
 
 Make sure we add the correct Integrator key for the client_id URL parameter and also make sure the redirect_uri parameter matches with the redirect uri you have setup under the integrator key.
 
 This will open up a consent screen. Click Accept
 
 ![Consent Screenshot](/images/Consent.JPG) 
 
 After clicking Accept you will be redirected to the redirect URI specified in the URI as well as the Integrator key. For the purpose of this recipe I am using 'https://localhost.com' so, if you are redirected to this URI it means that the consent has been granted successfully.
 
  ### 2. Note down DocuSign API UserName and API AccountID.
  - Login to your DocuSign Developer Sandbox and click on **Go to Admin** . 
  - Select **API and Keys** link which should be found under **'Integrations'**. 
  - Note down the **API Username** and **API AccountID**. This will be stored in Salesforce Custom Metadata.  

### 3. Install Source:
- Deploy the files present under the **src** folder to your Salesforce org. The src folder contains package package.xml which will help you to deploy the src.
- You can use Workbench for installation. Zip all the files such that folders and xml file present under src folder are at the root of the zip file.
- Login to Workbench
- Click on migration -> Deploy
- Select the zip file created in the earlier step. Check the **Single Package** checkbox and click on **Next**
- Click Deploy



### 4. Salesforce Custom Metadata setup:
- Once the source files have been deployed successfully to your Salesforce org, navigate to Setup -> Custom metadata types
- Click **Manage Records** under **DocuSignRESTSettings**
- Replace the values in the settings with the values for your DocuSign instance:
   - DSAccount  -> Your DocuSign API AccountID noted in step 2.
   - DSUserName -> Your DocuSign API Username noted in step 2.
   - RequestIntegratorKey -> Your Integrator Key Id created in step 1.
   - RequestPrivateKey -> Your Private Key created in step 1.
   
### 5. Salesforce Remote Site Settings: 
- Add 'https://account-d.docusign.com' as a Remote Site URL in your Salesforce instance. 
- Add the appropriate CLM REST API URL as a Remote Site URL in your Salesforce instance. You can find this in CLM Admin in the **Integrations** section of the **System Domains** page, or by consulting this chart: 

|                | **North America**               | **Europe**                      |
|----------------|---------------------------------|---------------------------------|
| **Test**       | https://apiuatna11.springcm.com | https://apiuateu11.springcm.com |
| **Production** | https://apina11.springcm.com    | https://apieu11.springcm.com    |


### 6. Access Token Demo: 
- Open Developer Console
- Press CTRL + E (open execute Anonymous code window)
- Add the following line of code :
  `DocuSignRestUtility.getAccessToken();`
- Highlight the added line of code and press **Execute Highlighted**  
- Navigate to the generated log file and choose *Debug Only* level to monitor the logs generated.
- If the Integration and setup is successfull you will notice a Status Code of 200 and the **ResponseAuthBody** parameter will also contain the `access_token`

![DeveloperConsole.JPG](/images/DeveloperConsole.JPG) 

### 7. Search CLM for a folder using Apex:
- Open Developer Console
- Press CTRL + E (open execute Anonymous code window)
- Add the following line of code :
  `DocuSignRestUtility.searchForFolder('SEARCH_QUERY');`
- Highlight the added line of code and press **Execute Highlighted**    

This should search your CLM instance for folders matching the search query.

## License

The DocuSign Java Client is licensed under the following [License](LICENSE).
