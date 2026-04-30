#勿用此腳本 未經測試
#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APP_VERSION_FILE="$ROOT_DIR/Ngaq.Core/Infra/AppVersion.cs"
ANDROID_CSPROJ="$ROOT_DIR/Ngaq.Frontend/proj/Ngaq.Android/Ngaq.Android.csproj"
WINDOWS_PROJECT="$ROOT_DIR/Ngaq.Frontend/proj/Ngaq.Windows/Ngaq.Windows.csproj"
LINUX_PROJECT="$ROOT_DIR/Ngaq.Frontend/proj/Ngaq.Linux/Ngaq.Linux.csproj"
ANDROID_PROJECT="$ROOT_DIR/Ngaq.Frontend/proj/Ngaq.Android/Ngaq.Android.csproj"
TEST_PROJECT="$ROOT_DIR/Ngaq.Test/proj/Ngaq.Windows.Test/Ngaq.Windows.Test.csproj"

VERSION=""
BUILD_ID=""
PLATFORMS="win,linux,android"
RUN_TESTS=1
RUN_I18N=1
ALLOW_DIRTY=0

usage() {
	cat <<'EOF'
Usage:
  sh ./ReleaseClients.sh --version 1.2.2 [options]

Options:
  --version <x.y.z>        Required. Release semver.
  --build-id <yydddHHMM>   Optional. Defaults to Asia/Shanghai current time.
  --platforms <list>       Comma-separated: win,linux,android
  --skip-tests             Skip Windows test publish + run.
  --skip-i18n              Skip GenI18n.sh.
  --allow-dirty            Allow local uncommitted changes before release.
  --help                   Show this message.

Examples:
  sh ./ReleaseClients.sh --version 1.2.2
  sh ./ReleaseClients.sh --version 1.2.2 --platforms win,android
EOF
}

log() {
	printf '[release] %s\n' "$1"
}

fail() {
	printf '[release] ERROR: %s\n' "$1" >&2
	exit 1
}

require_cmd() {
	command -v "$1" >/dev/null 2>&1 || fail "missing command: $1"
}

ensure_clean_git() {
	if [[ "$ALLOW_DIRTY" -eq 1 ]]; then
		return
	fi

	if ! git -C "$ROOT_DIR" diff --quiet HEAD -- || ! git -C "$ROOT_DIR" diff --cached --quiet || [[ -n "$(git -C "$ROOT_DIR" ls-files --others --exclude-standard)" ]]; then
		fail "git working tree is not clean; commit or stash changes first, or pass --allow-dirty"
	fi
}

validate_version() {
	[[ "$VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]] || fail "version must be x.y.z"
	[[ "$BUILD_ID" =~ ^[0-9]{9}$ ]] || fail "build id must be yydddHHMM (9 digits)"
}

parse_args() {
	while [[ $# -gt 0 ]]; do
		case "$1" in
			--version)
				[[ $# -ge 2 ]] || fail "--version requires a value"
				VERSION="$2"
				shift 2
				;;
			--build-id)
				[[ $# -ge 2 ]] || fail "--build-id requires a value"
				BUILD_ID="$2"
				shift 2
				;;
			--platforms)
				[[ $# -ge 2 ]] || fail "--platforms requires a value"
				PLATFORMS="$2"
				shift 2
				;;
			--skip-tests)
				RUN_TESTS=0
				shift
				;;
			--skip-i18n)
				RUN_I18N=0
				shift
				;;
			--allow-dirty)
				ALLOW_DIRTY=1
				shift
				;;
			--help|-h)
				usage
				exit 0
				;;
			*)
				fail "unknown argument: $1"
				;;
		esac
	done

	[[ -n "$VERSION" ]] || fail "--version is required"
	if [[ -z "$BUILD_ID" ]]; then
		BUILD_ID="$(TZ=Asia/Shanghai date +%y%j%H%M)"
	fi
}

contains_platform() {
	local needle="$1"
	case ",$PLATFORMS," in
		*",$needle,"*) return 0 ;;
		*) return 1 ;;
	esac
}

validate_platforms() {
	local item
	IFS=',' read -r -a items <<<"$PLATFORMS"
	for item in "${items[@]}"; do
		case "$item" in
			win|linux|android) ;;
			*) fail "unsupported platform: $item" ;;
		esac
	done
}

sync_versions() {
	local major minor patch
	IFS='.' read -r major minor patch <<<"$VERSION"
	local display_suffix="${BUILD_ID:0:5}"
	local android_display_version="$VERSION.$display_suffix"

	log "syncing version files to $VERSION ($BUILD_ID)"

	perl -0pi -e "s/public Version Ver \\{get;\\} = new \\([^\\)]*\\);/public Version Ver {get;} = new ($major, $minor, $patch, $BUILD_ID);/g; s/public Version CoreVer\\{get;\\} = new \\([^\\)]*\\);/public Version CoreVer{get;} = new ($major, $minor, $patch, $BUILD_ID);/g" "$APP_VERSION_FILE"
	perl -0pi -e "s#<ApplicationVersion>[^<]+</ApplicationVersion>#<ApplicationVersion>$BUILD_ID</ApplicationVersion>#g; s#<ApplicationDisplayVersion>[^<]+</ApplicationDisplayVersion>#<ApplicationDisplayVersion>$android_display_version</ApplicationDisplayVersion>#g" "$ANDROID_CSPROJ"
}

run_i18n() {
	if [[ "$RUN_I18N" -eq 0 ]]; then
		log "skipping i18n generation"
		return
	fi

	log "generating i18n resources"
	(
		cd "$ROOT_DIR"
		sh ./GenI18n.sh
	)
}

prepare_artifact_root() {
	local display_suffix="${BUILD_ID:0:5}"
	ARTIFACT_ROOT="$ROOT_DIR/artifacts/client/$VERSION.$display_suffix"
	rm -rf "$ARTIFACT_ROOT"
	mkdir -p "$ARTIFACT_ROOT"
}

copy_shared_assets() {
	local target_dir="$1"
	mkdir -p "$target_dir"
	cp -r "$ROOT_DIR/ExternalRsrc/." "$target_dir/"
}

prepare_android_assets() {
	local android_assets_dir="$ROOT_DIR/Ngaq.Frontend/proj/Ngaq.Android/Assets"
	rm -rf "$android_assets_dir"
	mkdir -p "$android_assets_dir"
	cp -r "$ROOT_DIR/ExternalRsrc/." "$android_assets_dir/"
}

run_tests() {
	if [[ "$RUN_TESTS" -eq 0 ]]; then
		log "skipping tests"
		return
	fi

	local test_output="$ARTIFACT_ROOT/test-runner"
	log "publishing and running Ngaq.Windows.Test"
	dotnet publish "$TEST_PROJECT" -c Release -r win-x64 -p:AllowMissingPrunePackageData=true -o "$test_output"
	"$test_output/Ngaq.Windows.Test.exe"
}

package_tar_gz() {
	local source_dir="$1"
	local archive_path="$2"
	local temp_dir="$3"
	rm -rf "$temp_dir"
	mkdir -p "$temp_dir"
	cp -r "$source_dir/." "$temp_dir/"
	find "$temp_dir" -name '*.pdb' -delete
	tar -czf "$archive_path" -C "$temp_dir" .
	rm -rf "$temp_dir"
}

publish_windows() {
	local publish_dir="$ARTIFACT_ROOT/windows/publish"
	local package_dir="$ARTIFACT_ROOT/windows/package"
	mkdir -p "$publish_dir" "$package_dir"

	log "publishing Windows client"
	dotnet publish "$WINDOWS_PROJECT" -c Release -r win-x64 --self-contained true -p:AllowMissingPrunePackageData=true -o "$publish_dir"
	copy_shared_assets "$publish_dir"
	package_tar_gz "$publish_dir" "$package_dir/Ngaq.Windows-win-x64.tar.gz" "$package_dir/_tmp"
}

publish_linux() {
	local publish_dir="$ARTIFACT_ROOT/linux/publish"
	local package_dir="$ARTIFACT_ROOT/linux/package"
	mkdir -p "$publish_dir" "$package_dir"

	log "publishing Linux client"
	dotnet publish "$LINUX_PROJECT" -c Release -r linux-x64 --self-contained true -p:AllowMissingPrunePackageData=true -o "$publish_dir"
	copy_shared_assets "$publish_dir"
	package_tar_gz "$publish_dir" "$package_dir/Ngaq.Linux-linux-x64.tar.gz" "$package_dir/_tmp"
}

publish_android() {
	local publish_dir="$ROOT_DIR/Ngaq.Frontend/proj/Ngaq.Android/bin/Release/net10.0-android/publish"
	local artifact_dir="$ARTIFACT_ROOT/android"
	mkdir -p "$artifact_dir"

	log "publishing Android client"
	prepare_android_assets
	dotnet publish "$ANDROID_PROJECT" -c Release -p:AllowMissingPrunePackageData=true

	shopt -s nullglob
	local files=("$publish_dir"/*.apk "$publish_dir"/*.aab)
	shopt -u nullglob
	[[ ${#files[@]} -gt 0 ]] || fail "android publish completed but no apk/aab found in $publish_dir"
	cp "${files[@]}" "$artifact_dir/"
}

write_release_info() {
	local info_file="$ARTIFACT_ROOT/release-info.txt"
	local display_suffix="${BUILD_ID:0:5}"

	cat >"$info_file" <<EOF
version=$VERSION
build_id=$BUILD_ID
display_version=$VERSION.$display_suffix
platforms=$PLATFORMS
run_tests=$RUN_TESTS
run_i18n=$RUN_I18N
generated_at=$(TZ=Asia/Shanghai date +%Y-%m-%dT%H:%M:%S%z)
artifact_root=$ARTIFACT_ROOT
EOF
}

main() {
	require_cmd dotnet
	require_cmd git
	require_cmd perl
	require_cmd tar

	parse_args "$@"
	validate_version
	validate_platforms
	ensure_clean_git
	prepare_artifact_root

	log "release root: $ARTIFACT_ROOT"
	sync_versions
	run_i18n
	run_tests

	if contains_platform win; then
		publish_windows
	fi
	if contains_platform linux; then
		publish_linux
	fi
	if contains_platform android; then
		publish_android
	fi

	write_release_info
	log "client release finished"
	log "artifacts: $ARTIFACT_ROOT"
}

main "$@"
