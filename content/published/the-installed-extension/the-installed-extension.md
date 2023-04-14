# Inspecting the Installed Extension

When troubleshooting a gateway extension or a DevOps platform that installs gateway extesions on API Connect, it can be useful to determine what is installed, what has propagated to the gateways, and what errors the extensions have thrown while deploying to the gateway.

In this article, I will cover two parts:

* [Viewing the installed extension on API Manager](#viewing-the-installed-extension-on-api-manager), and
* [Viewing the installed extension on DataPower](#viewing-the-installed-extension-on-datapower)

These instructions are tested on API Connect 10.0.5.2 using the Version 5 Compatibility mode. With extensions for the API Gateway, the process for reviewing the gateway on API Manager should be exactly the same, but there are notable differences for reviewing the gateway extensions on the gateway itself.

## Viewing the installed extension on API Manager

To see the contents of the gateway extension loaded, you can do the following:

```sh
$> apic gateway-extensions:get --scope org --org admin \
  --gateway-service [your_gateway_service] \
  --availability-zone availability-zone-default \
  --server [your_server] --output –
```

In the output, you’ll see a line that starts with url:

```
type: 'gateway_extension'
api_version: '2.0.0'
name: 'gateway-extension'
scope: 'org'
gateway_service_url: 'https://api.apic.moon/api/orgs/e46c05d5-54ae-4966-ade1-5daba3f15306/availability-zones/5de80c15-e383-4e02-9d9d-656cd9c9a3ac/gateway-services/75caf7d8-9c9e-4171-87da-555571419f9a'
created_at: '2023-04-13T18:58:43.000Z'
updated_at: '2023-04-13T18:58:43.000Z'
org_url: 'https://api.apic.moon/api/orgs/e46c05d5-54ae-4966-ade1-5daba3f15306'
url: 'https://api.apic.moon/api/orgs/e46c05d5-54ae-4966-ade1-5daba3f15306/availability-zones/5de80c15-e383-4e02-9d9d-656cd9c9a3ac/gateway-services/75caf7d8-9c9e-4171-87da-555571419f9a/gateway-extension'
```
 
Get an authorization token (if you’re logged in with the command line, there will be one in your `~/.apiconnect/token` file). It’s about 2700 characters long.

Now use cURL to make a request to the URL. 

```sh
$> curl -sk -H 'Authorization: Bearer [your token]' [url] | head -c 2000
```

You should see a value at `implementation.content` which is the start of the extension zip file, base64 encoded. Now let’s get the whole file. If you have jq installed, you can get it in one step with:

```sh
$> curl -sk -H 'Authorization: Bearer [your token]' [url] | \
  jq -r .implementation.content | base64 -d > extension.zip
```

The `extension.zip` file is the gateway extension as it is installed in the API Manager.

## Viewing the installed extension on DataPower

_These instructions are only applicable to gateways in Version 5 Compatibility mode._

When a gateway extension is installed, the gateway will unpack and import any configurations inside. The most notable file is in `local:///ext/extension_import_response.xml` in your API Connect Gateway Service's domain. 

> If you're using DataPower for Docker, an easy way to view the file is to `exec` into the pod and use `xmllint` to view it.
> 
> ```sh
> $> kubectl exec -it gwv5-0 -- xmllint --format \
>   /opt/ibm/datapower/drouter/local/apiconnect/ext/extension_import_response.xml
> ```
>
> As you can see, the Gateway's file system is in `/opt/ibm/datapower/drouter`.

Each configuration change in the gateway extension will be detailed in the `<exec-script-results>` section of the file, with a `status` of `SUCCESS` or `ERROR`.

## The API Gateway

API Gateway extensions can be packaged using gateway manifests, and these packages can contain five different types of files: `dp-import`, `extension`, `policy-v5`, `user-defined-policy`, and `user-defined-policy-yaml`. The `dp-import` process is similar to what I have shown above, but the other ones will have different processes and will look different when deployed into the API Gateway.

The zipped packages, however, are handled the same way by the API Connect CLI. They can by installed with `apic gateway-extensions:create`, removed with `apic gateway-extensions:delete`, updated with `...:update` and viewed with `...:get`.

## Conclusion

We followed a gateway extension that imports configurations into a gateway in Version 5 Compatibility mode. We viewed it on the API Manager, and checked its status on the gateway. In both cases, these are scriptable. DevOps can  detect failure automatically and notify developers for a quick fix. This is another way to promite quality in a fast-moving API mocroservices environment.
