#!/bin/bash

ENV=$1
if [ -z "${ENV}" ]; then
  ENV=moon
fi

DIR="$(cd "$(dirname "$0")"; pwd -L)"
set -e

# publisher=$(kubectl get secrets config -o json | \
#   jq -r '.data["secrets-moon.yaml"]' | \
#   base64 -d | yaml2json - | \
#   jq -r '.environment[]|select(.name="moon").config.publisher')
# secret=$(jq -r '.secret' <<< ${publisher})
# if [ -z "${secret}" ]; then
#   echo "Failed to get secret"
#   exit 1;
# fi

rundate=$(date "+%Y-%m-%d_%H:%M:%S")
isQuiet=false

if [ ! -e "${DIR}/modules/io.sh" ]; then
  echo "ERROR: no io module. Run the deployment process before proceeding."
  exit 1
fi
source ${DIR}/modules/io.sh

for i in curl jq json2yaml yamllint; do
  info "Testing for ${i}"
  if ! which ${i} >/dev/null; then
    error "Missing required package '${i}'. Install '${i}' before proceeding."
  fi
done

if [ ! -e "${DIR}/secrets/${ENV}.sh" ]; then
  error "missing secrets. Run the deployment process on env ${ENV} before proceeding."
  exit 1
fi
source ${DIR}/secrets/${ENV}.sh

function uploadContent {
  h1 Uploading content

  local rsyncExclude=''
  local rsyncDest
  if [ -z "${remoteHost}" ]; then
    rsyncDest=${remoteDir}
    mkdir -p "${remoteDir}"
  else
    rsyncDest="${remoteHost}:${remoteDir}"
  fi

  h2 "Sending ${DIR}/content/draft to ${rsyncDest}"

  rsync -avz -e ssh --stats --progress --delete ${DIR}/content/draft ${rsyncExclude} \
      ${rsyncDest}

  h2 "Sending ${DIR}/content/ready to ${rsyncDest}"

  rsync -avz -e ssh --stats --progress ${DIR}/content/ready ${rsyncExclude} \
      ${rsyncDest}

  h2 "Sending ${DIR}/content/retired to ${rsyncDest}"

  rsync -avz -e ssh --stats --progress ${DIR}/content/retire ${rsyncExclude} \
      ${rsyncDest}
}

function validateContent {
  h1 Prevalidating content
  for meta in $(find . -name meta.yaml); do
    if ! yamllint $meta; then
      echo FAILED to lint ${i}
      exit 1
    fi
  done
}

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
  echo "isQuiet ${isQuiet}"
  info "Publishing to ${apiEndpoint}"
  resultFile=$(mktemp)
  curl -k -X POST ${apiEndpoint} -H "X-CapnAjax-Secret: ${secret}" -d '' | tee ${resultFile}

  echo RESULT:
  cat ${resultFile} | jq

  numRecords=$(cat ${resultFile} | jq '.|length')

  for (( i = 0; i < numRecords; i++ )); do
    record=$(cat ${resultFile} | jq -r '.[$c]' --argjson c ${i})

    h1 RECORD
    jq <<< ${record}

    if [ 'file' == "$(jq -r '.class' <<< ${record})" ]; then
      h2 skipping file record
      continue
    fi

    contentItemName=$(jq -r '.name'  <<< ${record})
    action=$(jq -r '.action' <<< ${record})
    newStatus=$(jq -r '.status' <<< ${record})
    numFiles=$(jq -r '.files|length' <<< ${record})

    info action: ${action}
    info new status: ${newStatus}

    for (( j = 0; j < numFiles; j++ )); do

      local fileRecord=$(jq '.files[$c]' --argjson c ${j} <<< ${record})
      local pathname=$(jq -r '.path' <<< ${fileRecord})
      local type=$(jq -r '.type' <<< ${fileRecord})
      
      h2 FILE ${pathname}, type ${type}
      local content64=$(jq -r '.obj' <<< ${fileRecord})
      local fullpath="content/${action}/${contentItemName}/${pathname}"
      
      cat - <<< ${content64} | base64 -d > ${fullpath}
      
    done
    
    mv content/${action}/${contentItemName} \
      content/${newStatus}
  done

  rm ${resultFile}
}

validateContent
uploadContent
runPublish
