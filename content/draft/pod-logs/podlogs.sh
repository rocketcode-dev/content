#!/bin/bash

#
# Handy script to view the asset api logs. Tests if the correct pods are still
# deployment and filters out pods that are still Terminating
#

function printUsage {
  echo "Usage:"
  echo "  $0 [--selector=]<selector> [-h|--help] [--no-follow]"
  echo "  -h, --help - print this message"
  echo "  --no-follow - do not follow the logs"
  echo "  --selector - can be a label's name=value pair or just the app label's"
  echo "               value name. The --selector prefix is optional."
  exit $1
}

selectorParam=''
follow='-f'

while [[ $# -gt 0 ]]; do
  case $1 in 
  --no-follow)
    follow=''
    ;;
  --selector=*=*)
    selectorParam=$1
    ;;
  --selector=*)
    selectorParam=$(sed -e 's/=/=app=/' <<< ${1})
    ;;
  -h|--help)
    printUsage 0
    ;;
  *=*)
    selectorParam="--selector=${1}"
    ;;
  *)
    selectorParam="--selector=app=${1}"
    ;;
  esac
  shift
done

if [ -z "${selectorParam}" ]; then
  printUsage 1
fi

app=api

jqselector='.items[]|select(.spec.replicas==1)'
replicas=$(kubectl get rs ${selectorParam} -o json)

numReplicaSets=$(jq "[${jqselector}]|length" <<< $replicas)

if [ $numReplicaSets -gt 1 ]; then
  echo "Too many replica sets active. The one you're looking for is probably not ready yet."
  exit 1
elif [ $numReplicaSets -eq 0 ]; then
  echo "There are no valid replica sets. Check your selector is correct"
  exit 1
fi

podTemplateHash=$(jq -r "${jqselector}|.metadata.labels[\"pod-template-hash\"]" <<< $replicas)

kubectl logs --selector=pod-template-hash=${podTemplateHash} --tail=-1 ${follow}
