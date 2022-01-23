# Kubernetes API Patch

This document provides a recipe to patch a secret from within a pod. These instructions have been tested on a Red Hat OpenShift cluster in the IBM Cloud.

## Access

First thing you need is access to make the patch. Set up a service account, a role, give the service account the role, and tell your pod to use that role.

### Create the service account

This is the easiest part of the process. The only thing that is necessary is the name.

```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: certificates-job-sa
  namespace: assets-dev
```

### Create the role

The role is what defines what resources a service account has access to. In this example I create a role that has `get` access to service accounts and `get` and `patch` access to secrets. Rules are purely additive; a role cannot take permissions away.

There is also a `ClusterRole` resource for giving a service account access to things that affect the entire cluster, not just things in a single namespace.

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: certificate-admin
  namespace: assets-dev
rules:
- apiGroups:
  - ""
  resources:
  - serviceaccounts
  verbs:
  - get
- apiGroups:
  - ""
  resources:
  - secrets
  verbs:
  - get
  - patch
```

### Create a rolebinding

The role binding is what gives an account access to a role. If you need to bind a service account to a `ClusterRole`, use a `ClusterRoleBinding`

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: certificates-rolebinding
  namespace: assets-dev
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: Role
  name: certificate-admin
subjects:
- kind: ServiceAccount
  name: certificates-job-sa
  namespace: assets-dev
```

### Tell the pod to use your service account

This is simply adding the `serviceAccountName` to your pod's spec. If using a deployment or a job to create a pod, you can add it to the pod's spec there.

```yaml
  spec:
    serviceAccountName: certificates-job-sa
```

## Using the service account

If your pod, there will be a folder `/var/run/secrets/kubernetes.io/serviceaccount/` that has all the information you need to access the Kubernetes API server.

### Create your patch

To create a patch, you must use the JSON-patch format. This is a JSON array of operations. You can find a good reference at [http://jsonpatch.com]. In this case I am adding keys and certificates to an empty secret. Because this is a secret, the values need to be base64 encoded first.

This is whay my patch looks like:

```json
[ { "op" : "add",
    "path" : "/data",
    "value" : {
      "aet4i-apps.us-south.containers.appdomain.cloud.crt":"LS0t...0tCg==","aet4i-apps.us-south.containers.appdomain.cloud.key":"LS0t...LS0K","aet4i-apps.us-south.containers.appdomain.cloud.chain":"Ci01...LS0K","aet4i-apps.us-south.containers.appdomain.cloud.fullchain":"LS0t...0tCg=="
    }
  }
]
```

### Send the patch

In my case, I am using a shell script to patch the API. Use a kubernetes secret to do this.

```sh
  host=${KUBERNETES_SERVICE_HOST}:${KUBERNETES_PORT_443_TCP_PORT}
  namespace=$(cat /var/run/secrets/kubernetes.io/serviceaccount/namespace) 
  token=$(cat /var/run/secrets/kubernetes.io/serviceaccount/token)
  
  curl -sSik -X PATCH \
    https://${host}/api/v1/namespaces/${namespace}/secrets/https-certs \
    -H "Authorization: Bearer ${token}" \
    -H "Content-Type: application/json-patch+json" \
    -H "Accept: application/vnd.kubernetes.protobuf, application/json" \
    -T "${patchFile}" 
```

## Conclusion

We covered how to 
* Create a service account and give it access to your resources,
* How to run a pod using a service account, and
* How to access the Kubernetes API server from within a pod.

