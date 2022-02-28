# Secure Ingress to a secure backend

I have a secure service fronted by ingress in my Kubernetes cluster. Ingress had difficulty connecting. Frustratingly the cause of the problem was not clear.

In my application, I terminate TLS at the Ingress, but the backend services (the pods) are also secured, so Ingress needs to handle them. There are two ways for Ingress to communicate to a secure backend:

1. SSL Passthrough, also known as Layer 4 or TCP mode. In this case, Ingress is passing the encrypted packets directly through to the backend and the backend terminates SSL.
2. Ingress terminates SSL, then calls to a secure service on the backend.

These options have different benefits and drawbacks. Option 1 provides end-to-end encryption, necessary for Mutual TLS, but cannot handle path-based routing.

In this document, I will cover Option 2. This option is a bit more complex but sometimes necessary. Path-based routing is impossible with a Layer 4 proxy. Also my examples use HAProxy Ingress. Other Ingresses operate in the same way but annotation names and problem symptoms may be slightly different.

There are two paths we need to secure:

1. Client to Ingress
2. Ingress to backend

## Secure Client to Ingress

Create an SSL certificate and key. The CN of the certificate's subject or SAN must be the domain name. There are many ways to do this; if you have your own certificate authority, you may use openssl, or if you want to use a public certificate authority, a service like [Let's Encrypt](https://letsencrypt.org) might be more useful.

Once you have a certificate, stuff it into a [TLS secret](https://kubernetes.io/docs/concepts/configuration/secret/#tls-secrets).

Add the secret to your Ingress configuration:

```yaml
spec:
  tls:
  - hosts:
    - my-app.capnajax.com
    secretName: my-app-tls
  rules:
  - host: my-app.capnajax.com
    http:
      ...
```

The `secretName` here is, of course, the name of the kubernetes TLS secret for your external certificate.

## Secure Ingress to backend

Most backend apps are not secured; this is only necessary for secured pods.

If you are using a local certificate authority, you need to create a TLS secret containing the local CA's own certificate. You will also need a certificate for the backend service. The CN or a SAN of this certificate must literally be the name of the service.

Set the `server-ssl` and `ssl-redirect` annotations to `"true"`, and, if you're using a private CA, set the `server-ca` annotation to the name of a secret with the CA certificate (namespace/secret).

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  annotations:
    haproxy.org/server-ca: capnajax/ca
    haproxy.org/server-ssl: "true"
    haproxy.org/ssl-redirect: "true"
    kubernetes.io/ingress.class: haproxy
```

## If things are not right

Frustratingly, there are normally no error message to help you find the cause of a problem when certificates are the issue. 

When I had this problem, I had two main symptoms: 

```sh
$> curl -ki https://my-app.capnajax.com
curl: (56) Connection died, tried 5 times before giving up
```

This happened becase the subject of the external certificate was not right. Check the external certificate an its configuration. For testing purposes, disable `ssl-redirect`; when you do this, you can make an HTTP connection to port 80 but an HTTPS connection to port 443 should conitnue to fail this way.

```sh
$> curl -ki https://my-app.capnajax.com
HTTP/2 503
content-length: 107
cache-control: no-cache
content-type: text/html

<html><body><h1>503 Service Unavailable</h1>
No server is available to handle this request.
</body></html>
```

This happened because I did not tell Ingress I am connecting to a secure backend using the `server-ssl` annotation.

### Enable debug mode

If you need additional information, you may enable debug mode on the ingress itself. Note that this will enable debug for all ingresses on the cluster, not just yours.

Edit the kubernetes deployment

```sh
$> kubectl -n ingress edit deployments.apps kubernetes-ingress
```
Add the `--log=debug` argument to the `kubernetes-ingress-controller` container.

```yaml
    spec:
      containers:
      - args:
        - --default-ssl-certificate=ingress/kubernetes-ingress-default-cert
        - --configmap=ingress/kubernetes-ingress
        - --default-backend-service=ingress/kubernetes-ingress-default-backend
        - --ingress.class=haproxy
        - --publish-service=ingress/kubernetes-ingress
        - --log=debug
```

## Conclusion

In this document we covered:

1. Different ways to secure a service,
2. Securing the front-end of an Ingress,
3. Securing Ingress's backend when necessary, and
4. How to find problems in your TLS configuration.
