#!/usr/bin/env sh
set -eu

ROOT_DIR="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
BROWSER_PROJ_DIR="$ROOT_DIR/Ngan.Dict.Frontend/proj/Ngan.Dict.Browser"
SERVER_HTTP_PROJ_DIR="$ROOT_DIR/Ngan.Dict.Server/proj/Ngan.Dict.Server.Http"
SERVER_WWWROOT_PROJ="$SERVER_HTTP_PROJ_DIR/wwwroot"
SERVER_WWWROOT_BIN_RELEASE="$SERVER_HTTP_PROJ_DIR/bin/Release/net10.0/wwwroot"
SERVER_WWWROOT_BIN_DEBUG="$SERVER_HTTP_PROJ_DIR/bin/Debug/net10.0/wwwroot"
SERVER_WWWROOT_PUBLISH="$SERVER_HTTP_PROJ_DIR/bin/Release/net10.0/publish/wwwroot"

SRC_DEFAULT="$BROWSER_PROJ_DIR/bin/Release/net10.0-browser/publish/wwwroot"

if [ -d "$SRC_DEFAULT" ]; then
  SRC_DIR="$SRC_DEFAULT"
else
  SRC_DIR="$(find "$BROWSER_PROJ_DIR/bin/Release" -type d -path '*/publish/wwwroot' 2>/dev/null | head -n 1 || true)"
fi

if [ -z "${SRC_DIR:-}" ] || [ ! -d "$SRC_DIR" ]; then
  echo "error: could not find browser publish output."
  echo "hint: run 'dotnet publish -c Release' in Ngan.Dict.Browser first."
  exit 1
fi

sync_one() {
  target="$1"
  mkdir -p "$target"
  if command -v rsync >/dev/null 2>&1; then
    rsync -a --delete "$SRC_DIR"/ "$target"/
  else
    rm -rf "$target"/*
    cp -a "$SRC_DIR"/. "$target"/
  fi
  echo "  -> $target"
}

echo "synced:"
echo "  from: $SRC_DIR"
sync_one "$SERVER_WWWROOT_PROJ"
sync_one "$SERVER_WWWROOT_BIN_RELEASE"
sync_one "$SERVER_WWWROOT_BIN_DEBUG"
sync_one "$SERVER_WWWROOT_PUBLISH"
