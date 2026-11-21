import 'dart:io';
import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/foundation.dart';

const double kStarMobileFormFactorMaxShortestSide = 600;

const bool kStarMobileFormFactorBuild =
    // Compile-time flag for Linux mobile form factor testing.
    // ignore: do_not_use_environment
    bool.fromEnvironment('LINUX_MOBILE');

bool? _isRuntimeMobileFormFactor;

bool get isStarNativeMobileOs => Platform.isAndroid || Platform.isIOS;

bool get isStarNativeAndroid => Platform.isAndroid;

bool get isNativeVoiceCallKitPlatform => isStarNativeMobileOs;

bool _isStarDesktopClassOs() {
  return Platform.isLinux || Platform.isMacOS || Platform.isWindows;
}

void configureStarMobileDetection() {
  if (isStarNativeMobileOs || !_isStarDesktopClassOs()) {
    _isRuntimeMobileFormFactor = false;
    return;
  }
  if (kStarMobileFormFactorBuild) {
    _isRuntimeMobileFormFactor = true;
    return;
  }
  final FlutterView? view =
      PlatformDispatcher.instance.implicitView ??
      (PlatformDispatcher.instance.views.isNotEmpty
          ? PlatformDispatcher.instance.views.first
          : null);
  if (view == null) {
    _isRuntimeMobileFormFactor = false;
    return;
  }
  final double devicePixelRatio = view.devicePixelRatio;
  final Size logicalSize = view.physicalSize / devicePixelRatio;
  _isRuntimeMobileFormFactor = isStarRuntimeMobileFormFactorFromLogicalSize(
    logicalSize,
  );
}

@visibleForTesting
void debugSetStarRuntimeMobileFormFactor({required bool? value}) {
  _isRuntimeMobileFormFactor = value;
}

@visibleForTesting
bool isStarRuntimeMobileFormFactorFromLogicalSize(Size logicalSize) {
  if (logicalSize.isEmpty) {
    return false;
  }
  return isStarMobileFormFactorShortestSide(
    math.min(logicalSize.width, logicalSize.height),
  );
}

@visibleForTesting
bool isStarMobileFormFactorShortestSide(double shortestLogicalSide) {
  return shortestLogicalSide < kStarMobileFormFactorMaxShortestSide;
}

bool get isStarRuntimeMobileFormFactor {
  if (isStarNativeMobileOs || !_isStarDesktopClassOs()) {
    return false;
  }
  if (kStarMobileFormFactorBuild) {
    return true;
  }
  return _isRuntimeMobileFormFactor ?? false;
}

bool get isStarDesktopOs =>
    _isStarDesktopClassOs() && !isStarRuntimeMobileFormFactor;

bool get isStarMobileOs =>
    isStarNativeMobileOs || isStarRuntimeMobileFormFactor;

bool get isStarLinuxMobileVoiceTarget =>
    Platform.isLinux && isStarRuntimeMobileFormFactor;
