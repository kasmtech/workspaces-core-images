#! /bin/bash

## Parse input ##
FULLNAME="core-$1-$2"

if [[ "$1" == "$2" ]] ; then
  FULLNAME="core-$1"
fi

## Run readme updater ##
docker run -v $PWD/docs:/docs \
  -e RELEASE="$KASM_RELEASE" \
  -e DOCKER_USERNAME="$README_USERNAME" \
  -e DOCKER_PASSWORD="$README_PASSWORD" \
  -e DOCKERHUB_REPOSITORY="${ORG_NAME}/${FULLNAME}" \
  kasmweb/dockerhub-updater:develop
