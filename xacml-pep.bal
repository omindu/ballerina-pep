import ballerina.lang.jsons;
import ballerina.lang.messages;
import ballerina.net.http;
import ballerina.utils.logger;
import ballerina.lang.errors;
import ballerina.doc;
import ballerina.lang.strings;
import ballerina.utils;
import org.wso2.ballerina.connectors.basicauth;

@doc:Description{ value : "XACML client connector"}
@doc:Param{ value : "pdpEndpoint: The pdp endpoint url of the entitlement server"}
@doc:Param{ value : "userName: The username to authenticate with entitlement server"}
@doc:Param{ value : "password: The password of authenticate with entitlement server"}
connector XACMLConnector (string pdpEndpoint, string username, string password) {
    
    basicauth:ClientConnector basicAuthConnector = create basicauth:ClientConnector(pdpEndpoint,username,password);
    
    message authzRequest = {};
    json requestBody;

    @doc:Description{ value : "Get with basic authentication"}
    @doc:Param{ value : "xacmlConnector: The XACML Connector instance"}
    @doc:Param{ value : "subjectVar: The subject accessing the API resource. eg: User"}
    @doc:Param{ value : "resourceVar: The API resouce accessed from the request"}
    @doc:Param{ value : "actionVar: The http action done on the API resouce"}
    @doc:Return{ value : "true if authorized, else false"}
    action authorize (XACMLConnector xacmlConnector, string subjectVar, string resourceVar, string actionVar) (boolean) {
        
        requestBody = buildXACMLRequest(subjectVar,resourceVar,actionVar);
        messages:setHeader(authzRequest,"Content-Type","application/json");
        messages:setJsonPayload(authzRequest,requestBody);
        message decisionResponse;
        
        try {
            decisionResponse = basicauth:ClientConnector.post(basicAuthConnector, "", authzRequest);    
        } catch (errors:Error ex) {
            logger:error("Error occured while accessing the entitlement server: " + ex.msg);
            return false;
        }
        
        int status = http:getStatusCode(decisionResponse);
        
        if (status == 401) {
           logger:error("Unable to authenticate with entitlement server.");
           return false;
        } else if (status == 500) {
            logger:error("Error occured in the entitlement server. Response status: " + status);
            return false;
        } else if (status == 200) {
    
                json decisionJSONResponse = messages:getJsonPayload(decisionResponse);
                string decision = jsons:toString(decisionJSONResponse.Response[0].Decision);
                logger:debug(jsons:toString(decisionJSONResponse));
                
                if (decision == "Permit") {
                    return true;
                } else {
                    logger:debug("Response decision: " + decision);
                    return false;
                }
    
        } else {
            logger:error("Unexpected response code form entitlement server: " + status);
            return false;
        }
    }
}

function buildXACMLRequest( string subjectVar, string resourceVar, string actionVar) (json) {
    json body = {
                "Request": {
                    "Action": {
                        "Attribute": [{
                                "AttributeId": "urn:oasis:names:tc:xacml:1.0:action:action-id","Value": actionVar
                            }
                        ]},"Resource": {
                        "Attribute": [{
                                "AttributeId": "urn:oasis:names:tc:xacml:1.0:resource:resource-id","Value": resourceVar
                            }
                        ]},"AccessSubject": {
                       "Attribute": [{
                                "AttributeId": "urn:oasis:names:tc:xacml:1.0:subject:subject-id","Value": subjectVar
                            }
                        ]}
                }
            };
    return body;        
}

@http:config {basePath:"/securedService"}
service<http> SecuredService {

    @http:GET {}
    resource securedMessage (message m) {
        
        message response = {};
        boolean isAuthorized = true;
        string username;
        
        try {
            string authzHeader = messages:getHeader(m, "Authorization");
            string[] basic = strings:split(authzHeader, "Basic ");
            
            if (basic != null && basic[1] != "null") {
                
                string[] creds = strings:split(utils:base64decode(basic[1]), ":");
                
                if (creds != null && creds[0] != "null") {
                    username = creds[0];
                   
                } else {
                    
                    logger:error("Username cannot be found found in the request.");
                    http:setStatusCode(response, 401);
                    http:setContentLength(response, 0);
                    isAuthorized = false;
                }
                
            } else {
                
                logger:error("Credentials cannot be found in the request.");
                http:setStatusCode(response, 401);
                http:setContentLength(response, 0);
                isAuthorized = false;
            }
            
            if (isAuthorized) {
    
                XACMLConnector xacmlConnector = create XACMLConnector("https://localhost:9443/api/identity/entitlement/decision/pdp", "admin", "admin");
                isAuthorized = XACMLConnector.authorize(xacmlConnector, username, "/securedService/securedMessage", "read"); 
            }
            
            if (isAuthorized) {
                json payload = {"message":"The cake is a lie..."};
                messages:setJsonPayload(response, payload);
            } else {
                http:setStatusCode(response, 401);
                http:setContentLength(response, 0);
            }
        } catch (errors:Error ex) {
            logger:error("Authorization header cannot be found in the request.");
            http:setStatusCode(response, 401);
            http:setContentLength(response, 0);
        }    
        
        reply response;
    }
}
