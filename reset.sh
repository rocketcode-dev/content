#!/bin/bash

# Used for testing only
set -e

publisher=$(kubectl get secrets config -o json | \
  jq -r '.data["secrets-moon.yaml"]' | \
  base64 -d | yaml2json - | \
  jq -r '.environment[]|select(.name="moon").config.publisher')

secret=$(jq -r '.secret' <<< ${publisher})
remoteDir=$(jq -r '.remoteDir' <<< ${publisher})
remoteHost=$(jq -r '.remoteHost' <<< ${publisher})

set -x
echo remoteHost = ${remoteHost}
echo remoteDir = ${remoteDir}

ssh ${remoteHost} "sudo rm -rf ${remoteDir}/*" || true

kubectl exec -i $(kubectl get pods --selector=app=postgres \
    -o name) -- psql -U postgres --dbname=blog \
    <<< 'UPDATE articles SET primary_permalink_id = NULL;'

kubectl exec -i $(kubectl get pods --selector=app=postgres \
    -o name) -- psql -U postgres --dbname=blog \
    <<< 'DELETE FROM permalinks;'

kubectl exec -i $(kubectl get pods --selector=app=postgres \
    -o name) -- psql -U postgres --dbname=blog \
    <<< 'DELETE FROM articles;'