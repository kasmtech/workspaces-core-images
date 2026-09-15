#!/bin/bash
set -euo pipefail

NAME1=$1
NAME2=$2
ARCH=$3

image_uri="${ORG_NAME}/image-cache-private:${ARCH}-core-${NAME1}-${NAME2}-${SANITIZED_BRANCH}-${CI_PIPELINE_ID}"
echo "running /ci-scripts/verify-unit.sh in ${image_uri}"
docker run --rm \
    --volume ${CI_PROJECT_DIR}/ci-scripts/verify-unit.sh:/verify-unit.sh \
    --entrypoint /bin/bash \
    "$image_uri" \
    /verify-unit.sh \
    ;
