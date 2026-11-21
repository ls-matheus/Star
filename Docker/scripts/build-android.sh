#!/usr/bin/env bash
# Android debug build, in an ephemeral copy, never touching Star mobile originals.
set -euo pipefail

if [ ! -f /source/pubspec.yaml ]; then
  echo "ERRO: Star mobile nao foi montado em /source" >&2
  exit 2
fi
if [ ! -d /output ]; then
  echo "ERRO: diretorio de saida /output nao esta disponivel" >&2
  exit 2
fi
echo "Star mobile: preparando copia descartavel (sem segredos de distribuicao)..."
mkdir -p /work /output
tar -C /source \
  --exclude='./.git' \
  --exclude='./build' \
  --exclude='./.dart_tool' \
  --exclude='./.gradle' \
  --exclude='./.env' \
  --exclude='./.env.*' \
  --exclude='./android/key.properties' \
  --exclude='./android/measure.properties' \
  --exclude='./android/app/google-services.json' \
  --exclude='./ios/Runner/GoogleService-Info.plist' \
  --exclude='*.jks' \
  --exclude='*.p12' \
  --exclude='*.mobileprovision' \
  -cf - . | tar -C /work -xf -

cd /work
echo "Toolchain Flutter:"
flutter --version

# O snapshot Star mobile nao traz os arquivos Gradle Wrapper executaveis.
# Gera os arquivos do wrapper em projeto descartavel, sem alterar Gradle do Star.
if [ ! -f android/gradlew ] || [ ! -f android/gradle/wrapper/gradle-wrapper.jar ]; then
  echo "Gerando somente o Gradle Wrapper ausente em copia temporaria..."
  mkdir -p /tmp/star-gradle-wrapper
  flutter create --platforms=android --no-pub /tmp/star-gradle-wrapper
  test -f /tmp/star-gradle-wrapper/android/gradlew
  test -f /tmp/star-gradle-wrapper/android/gradle/wrapper/gradle-wrapper.jar
  cp /tmp/star-gradle-wrapper/android/gradlew android/gradlew
  mkdir -p android/gradle/wrapper
  cp /tmp/star-gradle-wrapper/android/gradle/wrapper/gradle-wrapper.jar android/gradle/wrapper/gradle-wrapper.jar
  chmod 0755 android/gradlew
fi
echo "Configurando variante OSS/UnifiedPush..."
dart tool/configure_build.dart --profile=oss
flutter pub get
bash tool/pub_get_packages.sh
dart run build_runner build --delete-conflicting-outputs
echo "Compilando APK debug (sem assinatura de publicacao)..."
flutter build apk --debug \
  --flavor canaryUnifiedpush \
  --dart-define-from-file=tool/dart_defines/canary.json \
  --dart-define=PUSH_PROVIDER=unifiedpush

shopt -s nullglob
apks=(build/app/outputs/flutter-apk/*.apk)
if [ "${#apks[@]}" -eq 0 ]; then
  echo "ERRO: compilacao terminou mas nao gerou APK." >&2
  exit 1
fi
for apk in "${apks[@]}"; do
  cp -f "$apk" "/output/$(basename "$apk")"
  echo "APK gerado: /output/$(basename "$apk")"
done
echo "Apenas build de teste. iOS usa Xcode no Mac; distribuicao exige assinatura propria."
