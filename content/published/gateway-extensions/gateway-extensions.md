# Gateway Extensions on API Connect

As you know, IBM DataPower Gateways come in four different form factors:

* The physical DataPower Gateway Appliance,
* DataPower Gateway for VMWare,
* DataPower Gateway for Linux, and
* DataPower Gateway for Docker.

Each of these form factors comes with different challenges, but unique among
these is the Docker edition for one reason: it doesn't normally persist its
configuration. When the other gateways reboot, it reboots into the existing
configuration, but the Docker gateway starts fresh.

To be fair, there are many environment variables that enable and configure
different features of the gateway, but this only provides limited access to
IBM DataPower Gateway's power and they are difficult to manage.

Even though the other form factors, Physical Appliances, VMWare, and Linux do
persist their configurations and can hold files, it's still a good practice
to favour Gateway Extensions to configure DataPower gateways used with API
Connect. Extensions maintain consistency across all gateways servers in a
cluster, simplifies adding or replacing a gateway appliance, and are easier
to manage with source control and DevOps.

In this article we're going to create a gateway extension that will

* [Build a user-defined policy](#building-a-user-defined-policy),
* [Construct a gateway extension](#constructing-the-gateway-extension),
* [Install a gateway extension in API Connect](#installing-the-gateway-extension), and
* [Bundling multiple extensions together](#bundling-multiple-extensions-together)

The examples in this article are targeted for the API Gateway on API
Connect version 10.0.5.1. The processes for V5 Compatibility mode and other
versions of API Connect are similar but have notable differences that are
outside of scope of this article.

## Building a user-defined policy

_Reference: [IBM Documentation](https://www.ibm.com/docs/en/api-connect/10.0.5.x_lts?topic=authoring-policies)_

In this example, I will create a user-defined policy that checks for a certain
username and password in a basic authentication header and set a variable with
an authenticated user's roles.

To do this, I have a policy chain with two steps:

1. Redact the headers I plan to set, to protect them from being manually set by
nefarious users, and
2. Run a GatewayScript to perform the authentication and set the headers.

I need to build a script that would run in the DataPower CLI. For this example,
I used two files, a `.cfg` which defined the extension, and an attached 
gatewayscript:

* [my-basic-auth.cfg](/posted/gateway-extensions/example-1/my-basic-auth.cfg)
* [basic-authentication.js](/posted/gateway-extensions/example-1/basic-authentication.js)

### Redact Policy

First I used a redact policy to suppress a few headers that could be misused. In
an API Assembly, that policy would look like this:

```yaml
- redact:
    version: 2.0.0
    title: x-authenticated-user-role
    redactions:
      - action: redact
        path: message.headers.x-authenticated-user
      - action: redact
        path: message.headers.x-authenticated-roles
```

In the config script, it looks more like this:

```
assembly-redact my-basic-auth_1.0.0_x-authenticated-user-role_0
  reset
  title "x-authenticated-user-role"
  correlation-path "$.x-ibm-configuration.assembly.execute[0]"
  redact-action message.headers.x-authenticated-user redact
  redact-action message.headers.x-authenticated-roles redact
exit  
```

> 🧑‍💻 Tip:
>
> In building these scripts, it's helpful to use the DataPower CLI to test and
> get info about the various commands. You may access the DataPower CLI with:
>
> ```
> kubectl attach -it <pod_name>
> ```
> 
> Note that this is `attach`, not `exec`. Using `exec` accesses the Linux
> operating system.
>
> Unattach from the gateway's console with `ctrl-P ctrl-Q`. Do not use
> `ctrl-C` because that will end the console causing the pod to crash and
> restart.

### GatewayScript Policy

The GatewayScript Policy is a little bit different because it has a file
attachment. When uploading the user-defined policy, the attachment will be
placed in the directory with that name.

```
assembly-gatewayscript my-basic-auth_1.0.0_gatewayscript_1
  reset
  title "basic-authentication"
  correlation-path "$.x-ibm-configuration.assembly.execute[1]"
  gatewayscript-location temporary:///filestores/extensions/gateway-extension/my-basic-auth/basic-authentication.js
exit
```

### Combining them into an assembly and building a function

```
api-rule my-basic-auth_1.0.0_main
  reset
  action my-basic-auth_1.0.0_x-authenticated-user-role_0
  action my-basic-auth_1.0.0_gatewayscript_1
exit

assembly my-basic-auth_1.0.0
  reset
  rule my-basic-auth_1.0.0_main
exit

assembly-function "my-basic-auth_1.0.0"
  reset
  summary "my-basic-auth-policy_1.0.0"
  title "Basic Authentication"
  assembly my-basic-auth_1.0.0
exit
```

## Constructing the Gateway Extension

Zip the files into an archive. All the files must be in the root directory
of the archive. No folders allowed.

```sh
$> cd example-1

# the -x parameters are only necessary on macOS
$> zip gw-extension.zip my-basic-auth.cfg basic-authentication.js -x ".DS_Store" -x "__MACOSX"
  adding: my-basic-auth.cfg (deflated 65%)
  adding: basic-authentication.js (deflated 58%)
```

You may have any number of extensions in a single archive. The extensions will
be processed in alphabetical order. It's a common practice to prefix `.cfg`
files with `01-`, `02-` etc when the order is important.

## Installing the Gateway Extension

If you don't already have the API Connect toolkit installed, you may download
it from the API Manager UI. Log into the API Manager and click the "Download
toolkit" tile.

```sh
$> cd ~/Downloads

$> unzip toolkit-mac_10.0.5.2.zip
Archive:  toolkit-mac_10.0.5.2.zip
  inflating: apic-slim

$> chmod u+x apic-slim

$> mv apic-slim ~/bin

$> cd <your extensions folder>
```

Log in to your server with the toolkit CLI.

```sh
$> apic identity-providers:list --scope admin --server <api endpoint hostname>
# output is a list of realms in the Cloud Manager, usually `default-idp-1`

$> apic login --server <api endpoint hostname> \
  --username admin --password <password> \
  --realm admin/<realm, usually `default-idp-1`>
```

Install the extension. The default availability zone is called `availability-zone-default`.

```sh
$> apic gateway-extensions:create gw-extension.zip \
  --scope org --org admin \
  --gateway-service <gateway service name> \
  --availability-zone <availability zone> \
  --server <api endpoint hostname>
```

Validate the extension's installation

```sh
apic gateway-extensions:get --scope org --org admin \
  --gateway-service <gateway service name> \
  --availability-zone <availability zone> \
  --server <api endpoint hostname> --output -
```

> 🧑‍💻 Tip:
>
> If you need to redeploy the extension, delete it first with the command
>
> ```sh
> $> apic gateway-extensions:delete --scope org --org admin \
>   --gateway-service <gateway service name> \
>   --availability-zone <availability zone> \
>   --server <api endpoint hostname>
> ```
>
> Then re-install with the same command as before

Next, you will need to force the API Manager to send the extension to the
gateway. This can be done by logging into the DataPower server UI and stopping and restarting the API Connect Gateway Service.

It may take a minute for the api manager to send the extension to the gateway.

## Bundling multiple extensions together

_This is only applicable to API Gateways_

In the next example I will add a few more extensions, but I will bundle them together and create a manifest file.

First we'll create an extension to enabled the Web Management Console and give
it an idle timeout of four hours (14,400 seconds).

Note that gateway extensions normally run in the gateway service's domain, so
it's important to switch to the `default` domain before configuring services
there.

For this example, I placed this script below in a `.cfg` file
([web-mgmt.cfg](/posted/gateway-extensions/example-2/web-mgmt.cfg)) and zipped it
into an archive called `web-mgmt.zip`.

```
top
configure terminal
domain default

web-mgmt
  admin-state enabled
  idle-timeout 14400
exit
```

Now create a manifest. This is a json file that describes how each extension
should be applied to the gateway.

_IBM Documentation: [Gateway extensions manifest](https://www.ibm.com/docs/en/api-connect/10.0.5.x_lts?topic=gateway-extensions-manifest)_

```json
{
  "extension": {
    "properties": {
      "deploy-policy-emulator": false,
      "deploy-policies": []
    },
    "files": [
      {
        "filename":"web-mgmt.zip",
        "deploy": "immediate",
        "type": "extension"
      },{
        "filename":"gw-extension.zip",
        "deploy": "immediate",
        "type": "extension"
      }
    ]
  }   
}
```

The `properties` section is only applicable for v5 policy emulation. Set
`deploy-policy-emulator` to `false` and `deploy-policies` to an empty array
unless you need v5 policy emulation for a migration.

The `files` section is more interesting. It contains a list of all the
extensions contained in the package and some instructions on how to apply them.
In this case, we want to apply the extensions `immediately` as opposed to
`deferred` (meaning it'll apply when the gateway service is restarted), and that
both of these files are extensions. For more information on what can go in this
manifest, consult the [IBM Documentation](https://www.ibm.com/docs/en/api-connect/10.0.5.x_lts?topic=gateway-extensions-manifest).

```sh
$> cp ../example-1/gw-extension.zip .

$> zip web-mgmt.zip web-mgmt.cfg -x ".DS_Store" -x "__MACOSX"
  adding: web-mgmt.cfg (deflated 15%)

$> zip manifest-extension.zip \
  manifest.json web-mgmt.zip gw-extension.zip -x ".DS_Store" -x "__MACOSX"
  adding: manifest.json (deflated 58%)
  adding: web-mgmt.zip (stored 0%)
  adding: ../example-1/gw-extension.zip (stored 0%)
```

Then install the extension the same way as before (removing the old one first)

```sh
$> apic gateway-extensions:delete --scope org --org admin \
  --gateway-service <gateway service name> \
  --availability-zone <availability zone> \
  --server  <api endpoint hostname>

$> apic gateway-extensions:create manifest-extension.zip \
  --scope org --org admin --gateway-service <gateway service name> \
  --availability-zone <availability zone> \
  --server  <api endpoint hostname>
```

Again, remember it may take a few minutes before the extension runs on the
gateways.

## Conclusion

In this article we covered building an extension for the API Gateway with  examples on building custom policies as well as general configurations, and we bundled multiple extensions together using a `manifest.json` file. In a [another article](/posted/gateway-configmaps), we also cover using Kubernetes configmaps to add files to the gateway's local file system. 

This is a good practice for any DataPower cluster that serves API Connect, but with DataPower for Docker on Kubernetes, it's critically important. It's the best way to ensure all gateways in a cluster are configured consistently, and to ensure new and refreshed gateways are configured quickly and correctly.

