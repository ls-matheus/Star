import 'dart:ui' show Size;

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:star_app/core/api/star_client_properties.dart';
import 'package:star_app/core/platform/star_platform.dart';

void main() {
  group('isStarMobileFormFactorShortestSide', () {
    test('returns true below the mobile breakpoint', () {
      expect(isStarMobileFormFactorShortestSide(599), isTrue);
    });

    test('returns false at or above the mobile breakpoint', () {
      expect(isStarMobileFormFactorShortestSide(600), isFalse);
      expect(isStarMobileFormFactorShortestSide(1280), isFalse);
    });
  });

  group('isStarRuntimeMobileFormFactorFromLogicalSize', () {
    test('treats an empty first-frame size as desktop', () {
      expect(
        isStarRuntimeMobileFormFactorFromLogicalSize(Size.zero),
        isFalse,
      );
      expect(
        isStarRuntimeMobileFormFactorFromLogicalSize(const Size(0, 800)),
        isFalse,
      );
    });

    test('treats a compact window as mobile form factor', () {
      expect(
        isStarRuntimeMobileFormFactorFromLogicalSize(const Size(390, 844)),
        isTrue,
      );
    });

    test('treats a wide window as desktop form factor', () {
      expect(
        isStarRuntimeMobileFormFactorFromLogicalSize(const Size(1280, 720)),
        isFalse,
      );
    });
  });

  group('resolveClientPlatform', () {
    test('reports linux mobile form factor as linux client platform', () {
      expect(
        resolveClientPlatform(TargetPlatform.linux, mobileFormFactor: true),
        'linux',
      );
    });

    test('reports desktop linux as desktop client platform', () {
      expect(resolveClientPlatform(TargetPlatform.linux), 'desktop');
    });
  });

  group('resolveDeviceClass', () {
    test('reports mobile form factor on desktop os as mobile device class', () {
      expect(
        resolveDeviceClass(TargetPlatform.linux, mobileFormFactor: true),
        'mobile',
      );
      expect(
        resolveDeviceClass(TargetPlatform.macOS, mobileFormFactor: true),
        'mobile',
      );
    });

    test('reports desktop form factor as desktop device class', () {
      expect(resolveDeviceClass(TargetPlatform.linux), 'desktop');
    });
  });

  group('buildStarClientUserAgent', () {
    test('uses Star Linux label for linux mobile platform', () {
      expect(
        buildStarClientUserAgent(
          clientPlatform: 'linux',
          clientVersion: '1.0.0',
          releaseChannel: 'beta',
        ),
        'Star Linux/1.0.0 (beta)',
      );
    });
  });
}
