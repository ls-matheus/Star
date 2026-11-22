#!/usr/bin/env bash
# Builds Star's Android debug APK on a Mac with the published Docker toolchain.
# No GitHub Actions or push required. The source mounts are read-only.
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
source_root="${STAR_SOURCE_ROOT:-$repo_root}"
output_dir="${STAR_ANDROID_OUTPUT:-$repo_root/Docker/output/local-android}"
cache_dir="${STAR_ANDROID_CACHE:-$HOME/Library/Caches/star-android-builder}"
image="${STAR_ANDROID_IMAGE:-ghcr.io/ls-matheus/star-mobile-builder@sha256:bc9138ede614aadb9b2f488525d463b0958f2988017acfff892ede53159e66a7}"
apk="$output_dir/Star-Android-ARM64-DEBUG.apk"

for expected in "$source_root/Star mobile/pubspec.yaml" "$source_root/Star web/Cargo.toml"; do
  if [ ! -f "$expected" ]; then
    echo "Missing full source at $expected; set STAR_SOURCE_ROOT to the complete project folder." >&2
    exit 2
  fi
done
if ! command -v docker >/dev/null 2>&1 || ! docker info >/dev/null 2>&1; then
  echo 'Docker engine is not running. Start the Colima container runtime first.' >&2
  exit 2
fi

mkdir -p "$output_dir" "$cache_dir"
echo "Building from: $source_root"
echo "Using image:   $image"
echo "APK output:    $apk"
echo 'Pulling missing toolchain layers (cached locally on subsequent builds) ...'
docker pull --platform linux/amd64 "$image"

docker run --rm --platform linux/amd64 \
  -e CI=true -e FLUTTER_SUPPRESS_ANALYTICS=true \
  -e PUB_CACHE=/cache/pub -e GRADLE_USER_HOME=/cache/gradle \
  -e CARGO_TARGET_DIR=/cache/cargo \
  -e CARGO_BUILD_JOBS=2 \
  -v "$source_root/Star mobile:/source:ro" \
  -v "$source_root/Star web:/source-web:ro" \
  -v "$cache_dir:/cache" \
  -v "$output_dir:/output" \
  "$image"

if [ ! -s "$apk" ]; then
  echo "Android build finished without the expected APK: $apk" >&2
  exit 1
fi
shasum -a 256 "$apk"
printf 'Created debug APK: %s\n' "$apk"

if [ "${STAR_ADB_INSTALL:-0}" = '1' ]; then
  adb_bin="${STAR_ADB_BIN:-adb}"
  "$adb_bin" devices -l
  if [ -n "${STAR_ADB_SERIAL:-}" ]; then
    "$adb_bin" -s "$STAR_ADB_SERIAL" install -r "$apk"
  else
    "$adb_bin" install -r "$apk"
  fi
  echo 'APK installed; inspect the launcher, splash, animated transition, and login.'
fi
