# Things every Kubernetes application should have

Make your Kubernetes application more stable and reliable for your users
by following these practices.

This article is intended for developers that deploy their applications to Kubernetes. It does not cover Kubernetes infrastructure administration or DevOps.

## One container image to rule them all

No container image should have any environment-specific configurations in them. The PRODUCTION environment should use the same image as used in QA. The images should be tagged with the environment they are used in.

If an official image is available for a service, such as a Postgres or Nginx server, it's best to use that official image directly. Of course, I would build an image for an ExpressJS app that I am developing myself, but even then, there would be only one build stream for all environment levels.

Configuration files specific to your environment should be added by mounting `ConfigMap`s or `Secret`s.

This has many benefits:

### Transparency

What happens when something goes wrong? Normally when a service is operating poorly, you can `exec` into the pod and see what's in the file system. You know where all the files are and what they mean, so you can review it, respin your image and push it to your registry right? Right?

Well, no. If the pod is `CrashLoopBackoff` you cannot `exec` in. And what if you're not in the office the day it crashed? Does your backup know the system as well as you do? Are you sure? Would you remember where everything is six months later? Would your backup remember what you told them six months ago?

What would you do if you had to diagnose an issue with a service you are only vaguely familiar with? Well, the first thing I would do is look at the `Deployment` for that service. What are the environment variables, and what are its volume mounts? From this I would know which config maps hold its configuration, and then I can read through them, cross reference it to the pod logs or events, and that would take me closer to the solution. This is far easier if the configs are exposed rather than buried in the image.

### Familiarity

Generally official images are well-documented and well-understood, rebuilt images less so. Someone who joined a company a week ago sees a problem with an Nginx pod and can solve it much easier without needing to know about all your customizations.

### Less Infrastructure to maintain

Avoiding a unnecessary container builds also means fewer images in your container registry, fewer updates to cull when your registry's disk quota fills up, and less chance of accidentally culling a build still in use.

If you're using an official image, it's easier to pick up security updates and there's one less pull secret to keep up to date. Also you can set your `imagePullPolicy` to `IfNotPresent` leading to fewer registry pulls and quicker startup times.

In general, standard images are less burden for both you and your servers.

## A `healthz` endpoint

The standard path for a `healthz` endpoint is:

```http
GET https://<your service hostname>/healthz
```

and it returns something trivial like `200 OK` or a JSON object with the sytem time or a code to identify the pod.

Importantly, the `healthz` endpoint is a status **reporting** tool, not a status **monitoring** tool. It doesn't test your app, it only responds to tell you if it's all good. It should be callable every second, all day, every day, with a sub-second timeout, and reliably respond when your app is healthy.

Some good practices to make your `healthz` endpoint more usable:

1. Eager-load configuration files and wait until all the configuration files are validated to open the port. This may lengthen the startup time, but it'll prevent Kubernetes from terminating a working pod if a new pod is failing to start.
1. Maintain a readiness-check state. This could be as simple as a global `setNotReady()` function or as complex as a suite of scheduled self-diagnostics, or a combination of the two. The important thing is that the `healthz` endpoint can check if a part of your app is complaining about a lack of readiness.
1. Watch your threads. If you are using a language with a non-blocking thread model, monitor all threads for deadlocking. A language with a blocking model, like `NodeJS` usually won't need this because a blocked thread will also block `healthz`.
1. It's better to respond quickly with an error status than to let a request timeout. The sooner Kubernetes knows there's a problem, the sooner it can respond to it and the fewer user-requests will be lost.
1. Crash constructively, part 1. If you're in a situation where an error that could cause data loss is detected and can't be corrected, force the pod to crash. Exit 1 and let the replica set start a new pod. This is not a great user experience, it could cause downtime or unfulfilled requests, but data loss is far worse.
1. Crash constructively, part 2. If your app will never start correctly, log the reason, exit 1 and let it go. A pod crashing on startup is a pod that won't cause an existing pod to terminate.

There are several benefits for having a `healthz` endpoint:

### Diagnostics

When a `healthz` endpoint is not responding, you can work backwards from the pod to find out where the broken link is. Here's a simple troubleshooting process that would be enabled just by having this endpoint available:

| If no, | then check: |
| --- | --- |
| Can you reach it directly from another pod?<br/>Exec into a pod in the same namespace and try `wget http://<podname>:port/healthz -O -` | Did the service start correctly? Is the port exposed in the deployment's container spec? Is it still running? Is it deadlocked? |
| Can you reach it from a `ClusterIP` service that was supposed to expose it?<br/>Exec into a pod in the same namespace and try `wget http://<servicename>:port/healthz -O -` | Is the `ClusterIP` service pointing to the correct port
| Can you reach it through Ingress?<br/>From your desktop try `wget http://<ingress-server>/healthz  --no-check-certificate --header='Host: <hostname>' -O -` | Is Ingress working? Is Ingress pointing to the service at the correct port? |
| Can you reach it through Ingress by URL?<br/>From your desktop try `wget http://<hostname>/healthz  -O -` | Is the DNS server pointing to the Ingress service? Is your TLS certificate up to date? |

All of these diagnostics are enabled solely by a `healthz` endpoint.

### Load Balancing

Some external load balancers test if a server is up simply by openning a port without actually sending a request. On many load balancers, such as f5, this is the default test because it's the most likely test to succeed on all services, and the least likely test to cause damage. But it doesn't work.

Remember your service is probably accessed via an ingress server. The load balancer would only be openening a port on the ingress, and never reaching back to your application. This means the load balancer is never actually testing connectivity to your service or your pod, so it'll never know if your pod is crashed.

### Readiness probes

The `healthz` endpoint can be used for container `livenessProbe`s, `readinessProbe`s, and `startupProbe`s.

A failed `startupProbe` can prevent an erroneous new pod from terminating a running pod. A failed `readinessProbe` can tell Kubernetes to route requests to other pods until the `readinessProbe`, and a failed `livenessProbe` can tell Kubernetes it's time to restart the pod.

## One-touch updates

Helm charts are the easiest way to manage consistency and portability between application environments. It should automate, putting keys into secrets, and configs into configmaps, and rebuilding the deployment.

Build scripts should automate building, uploading, and tagging images, and running quality checks on your code.

### Build script best practice: environment checking

Before starting, I always like to check that I am deploying to the correct environment, so I never update PRODUCTION before I am ready. This means I need to get two things right.

To ensure this, I add a command-line option to my script to name the environment, but I also check that the environment name I have provided matches my current Kubernetes context and namespace.

So the script has the `--env` parameter

```sh
./deploy.sh --env=production ...
```

This script knows that `production` environment deploys to the `prod` context and the `rocketcode` namespace. So an example script will check if that's the case:

```sh
  #!/bin/bash

  # get the --env arg
  for arg in $@; do
    case $arg in
    --env=*)
      deployment_env=${arg:6}
      ;;
    *)
      # other arguments
      ;;
    esac
  done

  # get the expected context and namespace for the environment
  case "${deployment_env}" in
  production)
    # set expected context and namespace for `production`
    expected_context='prod'
    expected_namespace='rocketcode'
    ;;
  # Add other environments here
  esac

  # Check the context, fail if the context is not right
  context=$(kubectl config current-context)

  if [ "${context}" != "${expected_context}" ]; then
    # fail
    echo "Current context: '${context}', expected: '${expected_context}'"
    exit 1
  fi
  
  # Check the namespace, fail if the namspace is not right
  namespace=$(kubectl config view --minify --output 'jsonpath={..namespace}')
  # default can sometimes read as blank
  if [ -z "${namespace}" ]; then
    namespace='default'

  if [ "${namespace}" != "${expected_namespace}" ]; then
    echo "Incorrect namespace: expecting '${expected_namespace}', got '${namespace}'."
    echo "Change context before proceeding with:"
    echo "    kubectl config set-context --current --namespace='${expected_namespace}'"
    exit 1    
  fi
```

## A Runbook

Eventually, your app will change. Your certificates will expire, or may get compromised and you'll need to replace them. Your base images may have CVE reports and you'll need to update them. The scope of your app will get bigger and you'll need to handle more endpoints.

These are not frequent changes, but they need to be handled accurately. You may not remember ever detail of how to do these in six months, or you may not be available to do them yourself.

A runbook, which could be as simple as a `README.md` file, will help you to remember what you had to do, or instruct your backup to do it if you're not available.

At the very minimum, it should document how to deploy and how to update certificates. Other contingencies that may not be intuitive should be there too.

## Conclusion

Nowadays, nearly every layer 7 application should be deployed on Kubernetes. It is the easiest platform to manage a complex suite of applications and it saves a lot of money on hardware and energy.

Like all great platforms, it's easy to hack it together until it works then struggle when problems happen later. But also, like every great platform, a little forethought can give you years of trouble-free operation as your app grows and evolves. We covered some good practices that can help you ready your application for a full life cycle of growth and stability.
