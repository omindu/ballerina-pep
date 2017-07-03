# ballerina-pep
A XACML policy enforcement point (PEP) using Ballerina.

This prject demonstrates on how to secure a API with XACML. The `xacml-pep.bal` includes a simple XACML client connector which can be used achieve the functionality of a PEP. This service is create with Ballerina v0.89.

The project contains two components. One is the `securedService` which represents the service we need to secure using XACML. The other component is the `XACMLConnector` which communicates with the policy decision point (PDP) providing the subject, resource and action inputs and obtains the PDP's decision for the given input.

## Usage of the XACML Connector

```
XACMLConnector xacmlConnector = create XACMLConnector(pdpEndpoint, username, password);
boolean isAuthorized = XACMLConnector.authorize(xacmlConnector, subject, resource, action);
```

### Input parameters

`pdpEndpoint` - The pdp endpoint url of the entitlement server.  
`username` - The username to authenticate with entitlement server.  
`password` - The password of authenticate with entitlement server.  

`xacmlConnector` - The XACML Connector instance.  
`subjectVar` - The subject accessing the API resource. eg: User.  
`resourceVar` - The API resouce accessed from the request.  
`actionVar` - The http action done on the API resouce.  

## Prerequisits

- Ballerina downloaded and installed [\[1\]]
- WSO2 Identity Server 5.3.0 [\[2\]]

## How to setup

- Start the Identit Server and login to the management console
- Click on **Policy Administation** and then on **Add New Entitlement Policy**.
![Policy Administration](https://github.com/omindu/ballerina-pep/blob/master/resources/images/image-1.png)
- Click on **Write Policy in XML**.
![Write Policy](https://github.com/omindu/ballerina-pep/blob/master/resources/images/image-2.png)
- Copy paste the content in [sample-policy.xml](https://github.com/omindu/ballerina-pep/blob/master/resources/sample-policy.xml) file and **Save**. This policy is inplace to authorize `READ` access to `/securedService/securedMessage` only to users having `admin` role.
![Save Policy](https://github.com/omindu/ballerina-pep/blob/master/resources/images/image-3.png)
- Click on **Publish to My PDP**.
![Publish Policy](https://github.com/omindu/ballerina-pep/blob/master/resources/images/image-4.png)
- Complete publishing the policy by clicking on **Publish**.
![Complete Policy Publish](https://github.com/omindu/ballerina-pep/blob/master/resources/images/image-5.png)

## Running the service

- Copy [xacml-pep.bal](https://github.com/omindu/ballerina-pep/blob/master/xacml-pep.bal) file.
- Run the following command.

```sh
curl -v -u admin:admin http://localhost:9090/securedService/securedMessage
```

If the user is not authorized, the service will return a `401 Unauthorized`. User a diffrent username to try it out.

**Note:** Even if we pass the password with the request, the `securedService` service does not handle authentication. It only extracts username from the Authorization header and pass it to the `XACMLConnector`.

## Service diagram
![Service Diagram](https://rawgit.com/omindu/ballerina-pep/master/resources/images/xacml-pep.svg)

[\[1\]]: <https://ballerinalang.org/>
[\[2\]]: <http://wso2.com/identity-and-access-management#download>
