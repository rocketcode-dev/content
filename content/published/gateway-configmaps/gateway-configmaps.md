# Adding Files to DataPower for Docker

Suppose you need a set of files to live in the `local:` file system on your gateway. Normally in DataPower, there are many ways to upload files, and to be fair, they exist in DataPower for Docker as well.

However, uploading files to a DataPower for Docker gateway is generally a bad idea, especially if using Kubernetes. If a gateway pod restarts, as it could do at any time, those files are lost.

Fortunately, the GatewayCluster CRD provides an easy way to place files in your `local:` filesystem using tarballs in ConfigMaps. This article shows you how.

This article assumes the gateway is installed with the GatewayCluster CRD as
provided with API Connect on Kubernetes.

## Mapping directories to a ConfigMap or a Secret

In my example, I am building a configmap from [gw-local-files.tar.gz](/posted/gateway-configmaps/example/gw-local-files.tar.gz). This tarball may contain files in a directory tree. A configmap can hold any number of tarballs, but the total size of the configmap cannot exceed 1 MiB.

```sh
$> kubectl create configmap gw-local-files --from-file=gw-local-files.tar.gz
configmap/gw-local-files created
```

For now, we'll also create a `dummy-cm` configmap for reasons we'll discuss soon. Download and apply [dummy-cm.yaml](/posted/gateway-configmaps/example/dummy-cm.yaml).

Then add this section to the `GatewayCluster` CRD:

```yaml
spec:
  additionalDomainConfig:
  - dpApp:
      config:
      - dummy-cm
      local:
      - gw-local-files
    name: apiconnect
```

Each entry in the `local:` array is a configmap created from a tarball, and each tarball is extracted into the root of the `local:` filesystem for the domain. You may build your `local:` directly from number of tarballs; the tarballs are extracted in the order they are listed.

In this config, I set the `dpApp.config` for the domain to `['dummy-cm']`. In order to apply the change, there needs to be a config listed in the domain's `dpApp.config` as well. The CRD does not permit an empty list of `config`s. Each entry in this list is the name of a configmap that contains `.cfg` files. This can be an opportunity, for example, to enable [web management](/posted/gateway-configmaps/example/web-mgmt-cm.yaml), or simply use the [dummy config](content/draft/gateway-configmaps/example/dummy-cm.yaml) we created earlier.

## Updating the files

To update the files, update or replace a configmap. This will immediately begin a rolling update of all the gateway pods in the statefulset. Unfortunately, this means that if there is only one gateway in the set, the gateway will be out of service for a few minutes while the new gateway starts up.

## Conclusion

In this article we explored a way to place files in a DataPower for Docker gateway's file system using a config map, and in the process we uncovered another way to add a configuration by adding an `additionalDomainConfig` to a GatewayCluster CRD.

The `additionalDomainConfig` in the GatewayCluster CRD is the same as the `domains` in the [DataPowerService CRD](https://www.ibm.com/docs/en/datapower-operator/1.6?topic=guides-domain-configuration#config-method-dpapp). Also, like the DataPowerService CRD `domains`, the `additionalDomainConfig` can create secrets and certificates.

These features make managing gateway containers easier in a way that only a kubernetes-based application server can. It turned a special challenge of managing a Kubernetes-based gateway into a special benefit of using it.
