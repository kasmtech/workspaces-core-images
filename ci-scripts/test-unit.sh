#!/bin/bash
set -euo pipefail

NAME1=$1
NAME2=$2
ARCH=$3

# This job's own Docker daemon isn't necessarily the same architecture as
# the image under test (e.g. it always runs on an amd64 runner -- see the
# ARCH comment in gitlab-ci.template -- while ARCH can be aarch64), and no
# cross-arch emulation is configured. `docker run --entrypoint /bin/bash`
# on a foreign-arch image would just fail with an exec format error before
# ever reaching the real per-arch verification in the Playwright/EC2 leg.
# Known gap, tracked for a follow-up to add proper emulation.
HOST_ARCH="$(uname -m)"
if [[ "${HOST_ARCH}" != "${ARCH}" ]]; then
  echo "Skipping local unit verification: runner is ${HOST_ARCH}, image is ${ARCH}, no emulation configured"
  exit 0
fi

image_uri="${ORG_NAME}/image-cache-private:${ARCH}-core-${NAME1}-${NAME2}-${SANITIZED_BRANCH}-${CI_PIPELINE_ID}"
echo "running /ci-scripts/verify-unit.sh in ${image_uri}"
docker run --rm \
    --volume ${CI_PROJECT_DIR}/ci-scripts/verify-unit.sh:/verify-unit.sh \
    --entrypoint /bin/bash \
    "$image_uri" \
    /verify-unit.sh \
    ;
