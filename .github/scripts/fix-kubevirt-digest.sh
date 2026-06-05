#!/usr/bin/env bash
# Replaces the amd64-specific digest Renovate sets for kubevirt-gpu-device-plugin
# with the correct multi-arch manifest list digest.
#
# Usage: ./fix-kubevirt-digest.sh <version>
# Example: ./fix-kubevirt-digest.sh v1.5.0

set -euo pipefail

VERSION="${1:?Usage: $0 <version> e.g. v1.5.0}"
IMAGE="nvcr.io/nvidia/kubevirt-gpu-device-plugin:${VERSION}"
CSV="bundle/manifests/gpu-operator-certified.clusterserviceversion.yaml"

echo "Fetching manifest list digest for ${IMAGE} ..."
DIGEST=$(docker buildx imagetools inspect "${IMAGE}" --format '{{.Manifest.Digest}}')

if [[ -z "${DIGEST}" ]]; then
  echo "ERROR: could not get manifest list digest for ${IMAGE}" >&2
  exit 1
fi

echo "Manifest list digest: ${DIGEST}"
echo "Updating ${CSV} ..."

sed -i "s|kubevirt-gpu-device-plugin:${VERSION}@sha256:[a-f0-9]*|kubevirt-gpu-device-plugin:${VERSION}@${DIGEST}|g" "${CSV}"

echo "Done. Verify with:"
echo "  grep kubevirt ${CSV}"
