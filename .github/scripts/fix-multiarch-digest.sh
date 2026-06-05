#!/usr/bin/env bash
# Replaces any amd64-specific digest Renovate sets for an nvcr.io image
# with the correct multi-arch manifest list digest, using the registry API.
#
# Usage: ./fix-multiarch-digest.sh <full-image-name> <version>
# Example: ./fix-multiarch-digest.sh nvcr.io/nvidia/cloud-native/vgpu-device-manager v0.4.2

set -euo pipefail

IMAGE_NAME="${1:?Usage: $0 <full-image-name> <version>}"
VERSION="${2:?Usage: $0 <full-image-name> <version>}"
CSV="bundle/manifests/gpu-operator-certified.clusterserviceversion.yaml"

REGISTRY="${IMAGE_NAME%%/*}"
REPO="${IMAGE_NAME#*/}"
SHORT_NAME="${IMAGE_NAME##*/}"

echo "Fetching manifest list digest for ${IMAGE_NAME}:${VERSION} via registry API ..."

# Discover auth realm from the registry's WWW-Authenticate challenge
AUTH_HEADER=$(curl -sf -I "https://${REGISTRY}/v2/" 2>/dev/null | grep -i "^www-authenticate:" | tr -d '\r' || true)
REALM=$(printf '%s' "${AUTH_HEADER}" | grep -oE 'realm="[^"]+"' | head -1 | cut -d'"' -f2)
SERVICE=$(printf '%s' "${AUTH_HEADER}" | grep -oE 'service="[^"]+"' | head -1 | cut -d'"' -f2)

if [[ -z "${REALM}" ]]; then
  echo "WARN: Could not get auth realm from ${REGISTRY} — skipping"
  exit 0
fi

# Get an anonymous pull token
TOKEN=$(curl -sf "${REALM}?service=${SERVICE}&scope=repository:${REPO}:pull" \
  | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('token', d.get('access_token', '')))")

if [[ -z "${TOKEN}" ]]; then
  echo "WARN: Could not obtain auth token for ${IMAGE_NAME} — skipping"
  exit 0
fi

# Request the manifest list; the digest is in the Docker-Content-Digest response header
DIGEST=$(curl -sf -I \
  -H "Authorization: Bearer ${TOKEN}" \
  -H "Accept: application/vnd.docker.distribution.manifest.list.v2+json,application/vnd.oci.image.index.v1+json" \
  "https://${REGISTRY}/v2/${REPO}/manifests/${VERSION}" \
  | grep -i "^docker-content-digest:" | awk '{print $2}' | tr -d '\r' || true)

if [[ -z "${DIGEST}" ]]; then
  echo "WARN: no manifest list found for ${IMAGE_NAME}:${VERSION} (single-arch or tag not found) — skipping"
  exit 0
fi

echo "Manifest list digest: ${DIGEST}"
sed -i "s|${SHORT_NAME}:${VERSION}@sha256:[a-f0-9]*|${SHORT_NAME}:${VERSION}@${DIGEST}|g" "${CSV}"
echo "Done."
