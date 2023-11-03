# Cheat notes: Mounting Volumes in Kubernetes

## Declare the volume

```yaml
spec:
  volumes:
    - name: my-volume
      configMap: # type of volume
        # volumes based on configMaps and secrets are both like this
        name: my-config-map
        # optional, if omitted will include everything
        items:
          - key: config_item
            path: name_of_config_item
      
```

## To mount as a volume

```yaml
spec:
  containers:
    - name: my-container
      volumeMounts:
        - name: my-volume
          mountPath: /data/my-folder
```
