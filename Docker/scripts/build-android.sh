#!/usr/bin/env bash
# SPDX-License-Identifier: AGPL-3.0-or-later
# Build a test APK inside a temporary container; source mounts are read-only.
set -euo pipefail

for f in /source/pubspec.yaml /source-web/Cargo.toml; do
  test -f "$f" || { echo "Missing required mounted source: $f" >&2; exit 2; }
done
test -d /output || { echo "Missing /output bind mount" >&2; exit 2; }

mkdir -p /work /work/shared-star /output
echo "Copying Star Mobile source to disposable build directory ..."
tar -C /source \
  --exclude='./.git' --exclude='./build' --exclude='./.dart_tool' \
  --exclude='./.gradle' --exclude='./.env' --exclude='./.env.*' \
  --exclude='./android/key.properties' --exclude='./android/measure.properties' \
  --exclude='./android/app/google-services.json' \
  --exclude='./ios/Runner/GoogleService-Info.plist' \
  --exclude='*.jks' --exclude='*.p12' --exclude='*.mobileprovision' \
  --exclude='*.keystore' -cf - . | tar -C /work -xf -

echo "Copying shared Star Web/Rust sources needed by mobile ..."
tar -C /source-web \
  --exclude='./.git' --exclude='./node_modules' --exclude='./target' \
  --exclude='./dist' --exclude='./.env' --exclude='./.env.*' \
  --exclude='./.pnpm-store' --exclude='./build' \
  --exclude='*.jks' --exclude='*.p12' --exclude='*.key' \
  --exclude='*.keystore' -cf - . | tar -C /work/shared-star -xf -
# The tracked Star mobile source includes star/README.md as a placeholder.
# Move that disposable copy out of the way: ln -s into an existing directory
# would create /work/star/shared-star and leave the real Rust workspace missing.
if [ -e /work/star ] || [ -L /work/star ]; then
  mv /work/star /work/star-placeholder
fi
ln -s /work/shared-star /work/star
test -L /work/star && test "$(readlink /work/star)" = /work/shared-star

# Native-assets build hooks run through Flutter/Dart subprocesses, whose PATH
# may differ from the interactive container shell. Use an absolute Cargo path.
export CARGO=/usr/local/cargo/bin/cargo
export STAR_SHARED_RUST_WORKSPACE=/work/star
test -x "$CARGO" || { echo "Missing Rust Cargo executable: $CARGO" >&2; exit 2; }
test -f "$STAR_SHARED_RUST_WORKSPACE/packages/markdown_parser/rust/Cargo.toml" || {
  echo "Missing shared Rust parser crate under $STAR_SHARED_RUST_WORKSPACE" >&2
  exit 2
}
test -f "$STAR_SHARED_RUST_WORKSPACE/Cargo.lock" || {
  echo "Missing shared Cargo.lock under $STAR_SHARED_RUST_WORKSPACE" >&2
  exit 2
}
echo "Native assets: Cargo $CARGO, Rust workspace $STAR_SHARED_RUST_WORKSPACE"

cd /work
# The publicly tracked debug key is only used for test APKs, not release signing.
if [ -f /source/android/app/debug.keystore ]; then
  cp /source/android/app/debug.keystore android/app/debug.keystore
fi

if [ ! -f android/gradlew ] || [ ! -f android/gradle/wrapper/gradle-wrapper.jar ]; then
  echo "Generating missing Gradle wrapper in a disposable Flutter project ..."
  flutter create --project-name star_gradle_wrapper --platforms=android --no-pub /tmp/star_gradle_wrapper
  mkdir -p android/gradle/wrapper
  cp /tmp/star_gradle_wrapper/android/gradlew android/gradlew
  cp /tmp/star_gradle_wrapper/android/gradle/wrapper/gradle-wrapper.jar android/gradle/wrapper/gradle-wrapper.jar
  chmod 0755 android/gradlew
fi

echo "Checking toolchains ..."
flutter --version
rustc --version
java -version
flutter config --enable-native-assets
if command -v sdkmanager >/dev/null 2>&1; then
  sdkmanager --channel=3 --install 'platforms;android-37.0' 'build-tools;37.0.0' ||
    sdkmanager --channel=3 --install 'platforms;android-37.2' 'build-tools;37.0.0'
  if [ -n "${ANDROID_HOME:-}" ] && [ ! -e "$ANDROID_HOME/platforms/android-37" ]; then
    sdk_dir="$(find "$ANDROID_HOME/platforms" -maxdepth 1 -type d -name 'android-37.*' | sort -V | head -1)"
    test -n "$sdk_dir"
    ln -s "$(basename "$sdk_dir")" "$ANDROID_HOME/platforms/android-37"
  fi
fi

echo "Configuring open-source UnifiedPush test build ..."
dart tool/configure_build.dart --profile=oss
flutter pub get
bash tool/pub_get_packages.sh
dart run build_runner build --delete-conflicting-outputs

echo "Building Android ARM64 debug APK (not store-signed) ..."
flutter build apk --debug \
  --flavor stableUnifiedpush \
  --target-platform android-arm64 \
  --dart-define-from-file=tool/dart_defines/stable.json \
  --dart-define=PUSH_PROVIDER=unifiedpush

shopt -s nullglob
apks=(build/app/outputs/flutter-apk/*.apk)
if [ "${#apks[@]}" -eq 0 ]; then
  echo "Android build produced no APK" >&2
  exit 1
fi
for apk in "${apks[@]}"; do
  output="/output/Star-Android-ARM64-DEBUG.apk"
  cp -f "$apk" "$output"
  sha256sum "$output"
  echo "Output: $output"
done
echo "WARNING: debug APK only; production signing and acceptance tests are separate."
