#!/bin/bash

## Parse input ##
NAME1=$(echo $1| awk -F'|' '{print $1}')
NAME2=$(echo $1| awk -F'|' '{print $2}')
BASE=$(echo $1| awk -F'|' '{print $3}')
BG=$(echo $1| awk -F'|' '{print $4}')
DISTRO=$(echo $1| awk -F'|' '{print $5}')
DOCKERFILE=$(echo $1| awk -F'|' '{print $6}')

## Build/Push image to cache endpoint by pipeline ID ##
docker build \
  -t ${ORG_NAME}/image-cache-private:$(arch)-core-${NAME1}-${NAME2}-${SANITIZED_BRANCH}-${CI_PIPELINE_ID} \
  --build-arg BASE_IMAGE="${BASE}" \
  --build-arg DISTRO="${DISTRO}" \
  --build-arg BG_IMG="${BG}" \
  -f ${DOCKERFILE} .
docker push ${ORG_NAME}/image-cache-private:$(arch)-core-${NAME1}-${NAME2}-${SANITIZED_BRANCH}-${CI_PIPELINE_ID}
