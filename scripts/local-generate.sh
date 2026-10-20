#!/usr/bin/env bash
#
# This script generates the API clients from a ref of ol-analytics-api.
# Usage: ./local-generate.sh
# Optionally, provide via environment variables:
#   SOURCE_REF (default: the newest release tag, which is what the release
#     pipeline generates from)
#   GENERATOR_VERSION (default: the version that generated the committed client,
#     so local and branch clients match the last release)
#
set -eo pipefail
shopt -u nullglob

if [ -z "$(which docker)" ]; then
	echo "Error: Docker must be available in order to run this script"
	exit 1
fi

SOURCE_REPO="https://github.com/mitodl/ol-analytics-api.git"
SOURCE_CLONE_DIR=$(mktemp -d)

# Read the version from origin/main rather than the working tree: the
# generator rewrites this file on every run.
REPO_ROOT="$(git -C "$(dirname "${BASH_SOURCE[0]}")" rev-parse --show-toplevel)"
RELEASED_VERSION_PATH="src/typescript/ol-analytics-dashboard-api-axios/src/.openapi-generator/VERSION"
if [ -z "${GENERATOR_VERSION:-}" ]; then
	if ! git -C "$REPO_ROOT" fetch -q origin main ||
		! RELEASED_VERSION="$(git -C "$REPO_ROOT" show "origin/main:$RELEASED_VERSION_PATH")"; then
		echo "Error: could not read $RELEASED_VERSION_PATH from origin/main; set GENERATOR_VERSION explicitly"
		exit 1
	fi
	GENERATOR_VERSION="v$(echo "$RELEASED_VERSION" | tr -d '[:space:]')"
fi
GENERATOR_IMAGE=openapitools/openapi-generator-cli:${GENERATOR_VERSION}

git clone -q --filter=blob:none "$SOURCE_REPO" "$SOURCE_CLONE_DIR"
# Releases are bare CalVer tags (2026.10.20.1); the pipeline matches them with
# the same pattern.
SOURCE_REF="${SOURCE_REF:-$(git -C "$SOURCE_CLONE_DIR" tag --list --sort=-v:refname | grep -E '^[0-9]{4}\.[0-9]{1,2}\.[0-9]{1,2}\.[0-9]+$' | head -n1)}"
git -C "$SOURCE_CLONE_DIR" checkout -q "$SOURCE_REF"

docker run --rm \
	-v "${REPO_ROOT}:/tmp/ol-analytics-api-clients" \
	-v "${SOURCE_CLONE_DIR}:/tmp/ol-analytics-api" \
	-w /tmp \
	"$GENERATOR_IMAGE" \
	./ol-analytics-api-clients/scripts/generate-inner.sh

# set permissions to host permissions so that we can modify files
docker run --rm \
	-v "${REPO_ROOT}:/local" \
	alpine \
	sh -c "chown \"\$(stat -c '%u:%g' /local)\" -R /local/src/"

rm -rf "$SOURCE_CLONE_DIR"

echo "Done.
 - API clients generated from ol-analytics-api ref: $SOURCE_REF
 - used OpenAPI Generator version: $GENERATOR_VERSION
"
