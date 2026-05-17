#!/usr/bin/env bash

set -euo pipefail

usage() {
	echo "Usage: $0 <csproj-path> <package-id> [package-version]"
	echo
	echo "Example:"
	echo "  $0 ./proj/Tsinswreng.CsU128Id/Tsinswreng.CsU128Id.csproj Tsinswreng.CsU128Id"
	echo "  $0 ./proj/Tsinswreng.CsU128Id/Tsinswreng.CsU128Id.csproj Tsinswreng.CsU128Id 0.0.1-alpha"
}

if [[ $# -lt 2 || $# -gt 3 ]]; then
	usage
	exit 1
fi

if ! command -v realpath >/dev/null 2>&1; then
	echo "realpath is required but not found in PATH."
	exit 1
fi

resolve_path() {
	local input="$1"
	local normalized="$input"

	if command -v cygpath >/dev/null 2>&1; then
		if [[ "$input" =~ ^[A-Za-z]:[\\/] ]]; then
			normalized="$(cygpath -u "$input")"
		fi
	fi

	realpath "$normalized"
}

PROJECT_PATH="$(resolve_path "$1")"
PACKAGE_ID="$2"
PACKAGE_VERSION="${3:-}"
PROJECT_DIR="$(dirname "$PROJECT_PATH")"
ARTIFACT_DIR="$PROJECT_DIR/artifacts"

# Fill these before publishing, or provide them from environment variables.
NUGET_SOURCE="${NUGET_SOURCE:-https://api.nuget.org/v3/index.json}"
NUGET_API_KEY="${NUGET_API_KEY:-__FILL_ME__}"

if [[ ! -f "$PROJECT_PATH" ]]; then
	echo "csproj not found: $PROJECT_PATH"
	exit 1
fi

if [[ "$NUGET_API_KEY" == "__FILL_ME__" ]]; then
	echo "NUGET_API_KEY is not set."
	echo "Export NUGET_API_KEY first, then rerun this script."
	exit 1
fi

if [[ -z "$PACKAGE_VERSION" ]]; then
	PACKAGE_VERSION="$(
		sed -n 's:.*<Version>\(.*\)</Version>.*:\1:p' "$PROJECT_PATH" | head -n 1
	)"
	if [[ -z "$PACKAGE_VERSION" ]]; then
		echo "Package version was not provided and <Version> was not found in $PROJECT_PATH"
		exit 1
	fi
fi

rm -rf "$ARTIFACT_DIR"
mkdir -p "$ARTIFACT_DIR"

dotnet pack "$PROJECT_PATH" \
	-c Release \
	-o "$ARTIFACT_DIR" \
	-p:PackageVersion="$PACKAGE_VERSION"

PACKAGE_PATH="$ARTIFACT_DIR/$PACKAGE_ID.$PACKAGE_VERSION.nupkg"

if [[ ! -f "$PACKAGE_PATH" ]]; then
	echo "Package not found: $PACKAGE_PATH"
	exit 1
fi

dotnet nuget push "$PACKAGE_PATH" \
	--api-key "$NUGET_API_KEY" \
	--source "$NUGET_SOURCE" \
	--skip-duplicate

echo "Published: $PACKAGE_PATH"
