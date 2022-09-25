# Deep linking in Vue.js apps in Kubernetes

Vue is ideal for single-page applications, but sometimes you still need to publish links to specific app features or content. Navigating within Vue apps is a lot different from standard web apps because the path of the URL is interpreted on the client side, not the server.

In fact, with most Vue.js apps, the server doesn't even understand paths. Any link to anything beyond `/` will typically return a `404` error. To make a deep link work, you need to do two things: tell the server you're deep linking and tell the vue app how to handle your URL.

## On the server side

Frustratingly, the hot-reloadable app for development (`npm run serve`) and the compiled and minified app for production (`npm run build`) behave differently. A development build will respond to all requests to all paths, but the production build will not.

```sh
curl http://my-vue-app.com/
# This respond with the vue app

curl http://my-vue-app.com/item/m7veojy3che1vkq3ib1kay0wmun467
# in the development builds, this will respond, but
# in the production build, it return a 404 error.
```

To handle this problem, on the server side, rewrite all links to dynamic content to `/`. For example, in an haproxy ingress, add an annotation to `/` to rewrite links to `/`. Be careful that you are only rewriting dynamic content links to `/`. Do not rewrite paths to images, styles, scripts, or other static content.

There are several ways of doing this, each with different merits. I will explore two here.

### Example: HAProxy Ingress config

Ingress provides an easy way to map a small number of known paths to `/`. This can be useful in a single-page app that needs to expose a small number of features. One example would be a NAS where `/` gets a dashboard with general information about the health of the NAS, but urls `/login` and `/config` for direct access to their features.

To do this, add the annotation `haproxy.org/path-rewrite: "/"` to rewrite all the matching URL paths to `/` and set up a path for each prefix I want rewritten. Add an additional ingress to handle content paths we don't want to rewrite, such as `/` and all static content.

Different ingresses, obviously, will use different annotations. For OpenShift 4.6+, use `haproxy.router.openshift.io/rewrite-target: "/"`

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  annotations:
    haproxy.org/ssl-redirect: "true"
    haproxy.org/path-rewrite: "/"
    kubernetes.io/ingress.class: haproxy
  name: my-vue-app-ingress
spec:
  rules:
  - host: my-vue-app.com
    http: 
      paths:
      - pathType: Exact
        path: /
        backend:
          service:
            name: my-vue-app-service
      - pathType: Exact
        path: /login
        backend:
          service:
            name: my-vue-app-service
      - pathType: Exact
        path: /config
        backend:
          service:
            name: my-vue-app-service
---
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  annotations:
    haproxy.org/ssl-redirect: "true"
    kubernetes.io/ingress.class: haproxy
  name: static-content-ingress
spec:
  rules:
  - host: my-vue-app.com
    http: 
      paths:
      - pathType: Prefix
        path: /
        backend:
          service:
            name: my-vue-app-service
```

In general, these annotations only rewrite the prefix of a url, so if you have something like `/item/m7veojy3che1vkq3ib1kay0wmun467`, rewriting to `/item` to `/` would request `/m7veojy3che1vkq3ib1kay0wmun467` from the server, and the server would respond with a `404`. For this reason, ingress annotations can only help you with a small number of known end points. If you want to rewrite entire patterns, add a web server between ingress and your app.

### Example: Intermediate web server with pattern matching

When linking to content, it's not feasible to add a path for each content item to an ingress config. Another way is to add an Nginx server to your pod, and have that rewrite the appropriate paths and, using a `proxy_pass` directive, get that path from your Vue app.

In this example, I created a `ConfigMap` with an `nginx.conf` file and a deployment with two containers, my Vue app and an Nginx server.

```yaml
apiVersion: v1
kind: ConfigMap
data:
  nginx.conf: |

    worker_processes 3;
    pid /tmp/nginx.pid;

    events {}

    http {
      client_body_temp_path /tmp/client_temp;
      proxy_temp_path       /tmp/proxy_temp_path;
      fastcgi_temp_path     /tmp/fastcgi_temp;
      uwsgi_temp_path       /tmp/uwsgi_temp;
      scgi_temp_path        /tmp/scgi_temp;
    
      server {
        listen 8088;

        rewrite ^/item(/.*)?$ / last;
        rewrite ^/folder(/.*)?$ / last;
        rewrite ^/edit(/.*)?$ / last;
        rewrite ^/login(/.*)?$ / last;

        location / {
          proxy_pass http://localhost:8080;
        }
      }
    }

metadata:
  name: my-vue-app-proxy
---
apiVersion: apps/v1
kind: Deployment
metadata:
  labels:
    app: my-vue-app
  name: my-vue-app
spec:
  selector:
    matchLabels:
      app: my-vue-app
  template:
    metadata:
      labels:
        app: my-vue-app
    spec:
      containers:
      - image: us.icr.io/my-vue-app:latest
        imagePullPolicy: Always
        name: www
        resources: {}
        ports:
        - containerPort: 8080
          protocol: TCP
      - image: nginx:stable-alpine
        imagePullPolicy: Always
        name: proxy
        resources: {}
        ports:
        - containerPort: 8088
          protocol: TCP
        volumeMounts:
        - name: proxy-config
          mountPath: /etc/nginx
          readOnly: true
      volumes:
      - name: proxy-config
        configMap:
          name: my-vue-app-proxy
--- 
apiVersion: v1
kind: Service
metadata:
  labels:
    app: my-vue-app
  name: my-vue-app
spec:
  ports:
  - name: www
    port: 8088
    protocol: TCP
  selector:
    app: my-vue-app
  type: ClusterIP
---
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: www
spec:
  rules:
  - host: my-vue-app.com
    http: 
      paths:
      - pathType: Prefix
        path: /
        backend:
          service:
            name: my-vue-app
            port:
              number: 8088
```

More examples with different types of servers are provided in the Vue Router's [Example Server Configurations](https://router.vuejs.org/guide/essentials/history-mode.html#example-server-configurations) documents. 

## On the client side

On the client side, we want to make sure that the URL displayed in the location bar is a URL a user can paste into another browser's location bar and see the same content.

When navigating through a Vue site, Vue does not actually load a new page, it updates the content displayed. Methods like `router.push` and `router.replace` or tags like `<router-link />` create the appearance of navigation without slow page refreshes. I'm not going to repeat the Vue Router docs here, but I will point out a two things that are important to deep linking.

[Programmatic Nvaigation](https://router.vuejs.org/guide/essentials/navigation.html) methods, especially `router.push` keep the URL displayed in the location bar accurate and the browser history and back button usable.

[History Modes](https://router.vuejs.org/guide/essentials/history-mode.html), in particul HTML5 mode keep URLs meaningful.

[Navigation Guards](https://router.vuejs.org/guide/advanced/composition-api.html#navigation-guards) are important to keeping a view up to date. Without this, if a view's parameters (e.g. a document name) change, the content might not because the parameters may not be reread into the view without the use of an `onBeforeRouteUpdate` navigation guard to ensure the view is updated.

It is wise to make yourself familiar with the workings of Vue Router in general.

### 404 errors

The server configurations above have an unfortunate side effect of suppressing 404 errors, because any content not known is assumed to be `/`. It is up to you to provide a simulated 404 error page to catch all non-existent content. This can be done with Vue Router as well.

## Conclusion

In this document we covered how to use Vue.js's features to provide meaningful URLs and document histories, and how to configure Kubernetes Ingress and an HTTP server in your pod to work with Vue.js URLs. Working together, these enable deep linking content or features in your Vue.js app for bookmarkability and sharability and make Vue.js more useful for content-heavy web applications.
