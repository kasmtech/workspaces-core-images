#! /bin/bash

## Parse input ##
FULLNAME="core-$1-$2"

if [[ "$1" == "$2" ]] ; then
  FULLNAME="core-$1"
fi

## Run readme updater ##
docker run -v $PWD/docs:/docs \
  -e RELEASE="$KASM_RELEASE" \
  -e QUAY_API_KEY="$QUAY_API_KEY" \
  -e QUAY_REPOSITORY="${MIRROR_ORG_NAME}/${FULLNAME}" \
  kasmweb/dockerhub-updater:develop
