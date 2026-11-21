import 'package:flutter/foundation.dart';
import 'package:star_app/core/app_lock/app_lock_biometric_authenticator.dart';
import 'package:star_app/l10n/generated/star_localizations.dart';

String? appLockBiometricLabel(
  StarLocalizations l10n,
  List<AppLockBiometricKind> kinds,
) {
  if (kinds.isEmpty) {
    return null;
  }
  final List<String> labels = <String>[
    for (final AppLockBiometricKind kind in kinds) _kindLabel(l10n, kind),
  ];
  if (labels.length == 1) {
    return labels.single;
  }
  return l10n.appLockBiometricEither(labels.first, labels.last);
}

String _kindLabel(StarLocalizations l10n, AppLockBiometricKind kind) {
  final bool isIos = defaultTargetPlatform == TargetPlatform.iOS;
  return switch (kind) {
    AppLockBiometricKind.face =>
      isIos ? l10n.appLockBiometricFaceId : l10n.appLockBiometricFaceUnlock,
    AppLockBiometricKind.fingerprint =>
      isIos ? l10n.appLockBiometricTouchId : l10n.appLockBiometricFingerprint,
    AppLockBiometricKind.generic => l10n.appLockBiometricGeneric,
  };
}
