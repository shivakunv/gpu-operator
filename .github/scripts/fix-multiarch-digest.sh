#!/usr/bin/env bash
# Replaces any amd64-specific digest Renovate sets for an nvcr.io image
# with the correct multi-arch manifest list digest.
#
# Usage: ./fix-multiarch-digest.sh <full-image-name> <version>
# Example: ./fix-multiarch-digest.sh nvcr.io/nvidia/cloud-native/vgpu-device-manager v0.4.2

set -euo pipefail

IMAGE_NAME="${1:?Usage: $0 <full-image-name> <version>}"
VERSION="${2:?Usage: $0 <full-image-name> <version>}"
FULL_REF="${IMAGE_NAME}:${VERSION}"
CSV="bundle/manifests/gpu-operator-certified.clusterserviceversion.yaml"

echo "Fetching manifest list digest for ${FULL_REF} ..."
DIGEST=$(docker buildx imagetools inspect "${FULL_REF}" 2>/dev/null | grep "^Digest:" | awk '{print $2}')

if [[ -z "${DIGEST}" ]]; then
  echo "WARN: no manifest list found for ${FULL_REF} (single-arch image or tag not found) — skipping"
  exit 0
fi

SHORT_NAME="${IMAGE_NAME##*/}"
echo "Manifest list digest: ${DIGEST}"

sed -i "s|${SHORT_NAME}:${VERSION}@sha256:[a-f0-9]*|${SHORT_NAME}:${VERSION}@${DIGEST}|g" "${CSV}"

echo "Done. Verify with:"
echo "  grep '${SHORT_NAME}' ${CSV}"
