# Cheat notes: Kubernetes One-Liners

## Monitoring

I keep a terminal open with this one running at all times. It's similar to `kubectl get all` but I get to choose what `all` means and it adds a little bit of colour to the output.

```sh
watch -c '\
  for i in pod service deployment ingresses cronjob job; do \
    echo "\x1b[93m[\x1b[36;1m$i\x1b[0m\x1b[93m]\x1b[0m" ; \
    kubectl get $i -o wide ; echo; \
  done'
```


## Development

When I'm developing an app, I frequently restart deployments. Unfortunately, this causes a build-up of zero-desired `replicaset`s. This command cleans them up. It requires `jq`.

```sh
kubectl get rs -o json | \
  jq -r '.items[]|select(.spec.replicas==0)|.metadata.name' | \
  xargs kubectl delete rs
```
