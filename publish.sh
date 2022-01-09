#!/bin/bash

ENV=moon

DIR="$(cd "$(dirname "$0")"; pwd -L)"
set -e

rundate=$(date "+%Y-%m-%d_%H:%M:%S")

if [ ! -e ${DIR}/modules/io.sh ]; then
  echo "ERROR: no io module. Run the deployment process before proceeding."
  exit 1
fi
source ${DIR}/modules/io.sh

for i in curl jq json2yaml; do
  info "Testing for ${i}"
  if ! which ${i} >/dev/null; then
    error "Missing required package '${i}'. Install '${i}' before proceeding."
  fi
done

if [ ! -e ${DIR}/secrets/${ENV}.sh ]; then
  error "missing secrets. Run the deployment process on env ${ENV} before proceeding."
  exit 1
fi
source ${DIR}/secrets/${ENV}.sh

function uploadContent {
  h1 Uploading content

  local rsyncExclude=''

  h2 "Sending ${DIR}/content/drafts to ${remoteHost}:${remoteDir}"

  rsync -avz -e ssh --stats --progress --delete ${DIR}/content/drafts ${rsyncExclude} \
      ${remoteHost}:${remoteDir}

  h2 "Sending ${DIR}/content/ready to ${remoteHost}:${remoteDir}"

  rsync -avz -e ssh --stats --progress ${DIR}/content/ready ${rsyncExclude} \
      ${remoteHost}:${remoteDir}

  h2 "Sending ${DIR}/content/retired to ${remoteHost}:${remoteDir}"

  rsync -avz -e ssh --stats --progress ${DIR}/content/retired ${rsyncExclude} \
      ${remoteHost}:${remoteDir}
}
uploadContent

function contentRetired {
  local folder=$1
  local meta=$2
  info retired $1
  mv ${meta} ${DIR}/content/retire/${folder}
  mv ${DIR}/content/retire/${folder} ${DIR}/content/retired/${folder} 
}

function contentPublished {
  local folder=$1
  local meta=$2
  info published $1
  mv ${meta} ${DIR}/content/ready/${folder}
  mv ${DIR}/content/ready/${folder} ${DIR}/content/posted/${folder} 
}

function contentError {
  local folder=$1
  local meta=$2
  shift; shift;
  error "error in ${folder}: "
  for i in $@; do
    error " --> $(base64 -d <<< ${i})"
  done
  mkdir -p ${DIR}/content/error/${rundate}
  mv ${meta} ${DIR}/content/ready/${folder}
  mv ${DIR}/content/ready/${folder} ${DIR}/content/error/${rundate}/${folder}
  info "errorred content in content/error/${rundate}/${folder}: "
}

function runPublish {
  publishResult=$(curl -X POST ${apiEndpoint})
  

}
runPublish
