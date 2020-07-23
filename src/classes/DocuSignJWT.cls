/* This class is responsible for constructing the JSON Web Token */
/* JSON Web Token will be sent to the DocuSign Authentication service for getting an access token which will be used in subsequent DocuSign API Calls */
/* Visit https://developers.docusign.com/esign-rest-api/guides/authentication/oauth2-jsonwebtoken for additional information on JSON Web token in DocuSign API */


public class DocuSignJWT {
    
    public String alg {get;set;} //RS256 for DocuSign REST integration
    public String iss {get;set;} // Integrator key
    public String sub {get;set;} // DSFProUserName from the user record
    public String aud {get;set;} // Authentication domain
    public String scope {get;set;} // signature scope
    public String privateKey {get;set;} //Private key 
    public String exp {get;set;} 
    public String iat {get;set;}
    public Map<String,String> claims {get;set;}
    public Integer validFor {get;set;}
    public String cert {get;set;}
    public static final String HS256 = 'HS256';
    public static final String RS256 = 'RS256';
    public static final String NONE = 'none';
    private static final String STRING_EMPTY = '';


    //Constructor 
    public DocuSignJWT(String alg,String sub,String iss, String privateKey,String scope,String aud) {
        this.alg = alg; 
        this.sub = sub; 
        this.iss = iss; 
        this.privateKey = privateKey; 
        this.scope = scope; 
        this.validFor = 300; 
        this.aud = aud; 
    }
    
    //Method which returns the JSON Web Token
    public String issue() {
        String jwt = STRING_EMPTY;
        
        //Construct the JSON Web Token Header 
        JSONGenerator header = JSON.createGenerator(false);
        header.writeStartObject();
        header.writeStringField('alg', this.alg);
        header.writeStringField('typ','JWT'); // Set as JWT
        header.writeEndObject();
        String encodedHeader = base64URLencode(Blob.valueOf(header.getAsString()));
        
        //Construct the JSON Body             
        JSONGenerator body = JSON.createGenerator(false);
        body.writeStartObject();
        body.writeStringField('iss', this.iss);
        body.writeStringField('sub', this.sub);
        body.writeStringField('aud', this.aud);
        Long rightNow = (dateTime.now().getTime()/1000)+1;
        body.writeNumberField('iat', rightNow);
        body.writeNumberField('exp', (rightNow + validFor));
        body.writeStringField('scope', this.scope);
        if (claims != null) {
            for (String claim : claims.keySet()) {
                body.writeStringField(claim, claims.get(claim));
            }
        }
        body.writeEndObject();
        
        //JSON Web Token in this stage = encodedHeader + . + encodedBody
        jwt = encodedHeader + '.' + base64URLencode(Blob.valueOf(body.getAsString()));
        
    	//Sign with Private key to create the signature 
        if (this.alg == HS256 ) {
            Blob key = EncodingUtil.base64Decode(privateKey);
            Blob signature = Crypto.generateMac('hmacSHA256',Blob.valueof(jwt),key);
            jwt += '.' + base64URLencode(signature);  
        } 
        else if (this.alg == RS256 ) {
            Blob signature = null;   
            if (cert != null) {
                signature = Crypto.signWithCertificate('rsa-sha256', Blob.valueOf(jwt), cert);
            } else {
                Blob privateKeyBlob = EncodingUtil.base64Decode(privateKey);
                //construct the signature
                signature = Crypto.sign('rsa-sha256', Blob.valueOf(jwt), privateKeyBlob);
            }
            jwt += '.' + base64URLencode(signature);  
        } else if ( this.alg == NONE ) {
            jwt += '.';
        }
        return jwt;
        
    }
    
    //Utility method for returning the base64URLEncoded string for the input string
    private String base64URLencode(Blob input){ 
        String output = STRING_EMPTY;
        if (input != null) {
            output = encodingUtil.base64Encode(input);
            output = output.replace('+', '-');
            output = output.replace('/', '_');
            while ( output.endsWith('=')){
                output = output.subString(0,output.length()-1);
            }
        }    
        return output;
    }   

}
