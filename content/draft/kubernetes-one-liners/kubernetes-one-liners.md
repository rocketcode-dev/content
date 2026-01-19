# Cheat notes: Kubernetes One-Liners

## Development

When I'm developing an app, I frequently restart deployments. Unfortunately, this causes a build-up of empty `replicaset`s. This command cleans them up. It requires `jq`.

```sh
kubectl get rs -o json | \
  jq -r '.items[]|select(.spec.replicas==0)|.metadata.name' | \
  xargs kubectl delete rs
```

## Selector

Use the `--selector` instead of naming the pod the name of the pod. This allows you to view a restarted pod simply by going back through your command history. It's easier to script this way too.

For viewing logs:

```sh
kubectl logs --selector=app=my-api-application --tail=-1 -t
```

The `kubectl exec` doesn't support the `--selector` option _per se_ but you can still use it by wrapping it in another command

```sh
kubectl exec -it $(kubectl get pods --selector=app=my-api-application -o name) -- sh
```

## Logs

## Monitoring

I keep a terminal open with this one running at all times. It's similar to `kubectl get all` but I get to choose what `all` means and it adds a little bit of colour to the output.

```sh
watch -c '\
  for i in pod service deployment ingresses cronjob job; do \
    echo "\x1b[93m[\x1b[36;1m$i\x1b[0m\x1b[93m]\x1b[0m" ; \
    kubectl get $i -o wide ; echo; \
  done'
```
