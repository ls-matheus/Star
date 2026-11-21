import 'package:flutter_test/flutter_test.dart';
import 'package:star_app/core/bootstrap/image_cache_config.dart';

void main() {
  test('desktop gets the largest byte and entry budget', () {
    expect(starImageCacheBudget(isDesktop: true, isLowMemory: true), (
      bytes: kDesktopImageCacheMaxBytes,
      entries: kDesktopImageCacheMaxEntries,
    ));
  });

  test('mobile budgets depend on device memory', () {
    expect(starImageCacheBudget(isDesktop: false, isLowMemory: false), (
      bytes: kMobileImageCacheMaxBytes,
      entries: kMobileImageCacheMaxEntries,
    ));
    expect(starImageCacheBudget(isDesktop: false, isLowMemory: true), (
      bytes: kLowMemoryImageCacheMaxBytes,
      entries: kLowMemoryImageCacheMaxEntries,
    ));
  });

  test('entry limits scale with the byte budget and never drop below '
      'the framework default', () {
    expect(
      kDesktopImageCacheMaxEntries,
      greaterThan(kMobileImageCacheMaxEntries),
    );
    expect(
      kMobileImageCacheMaxEntries,
      greaterThan(kLowMemoryImageCacheMaxEntries),
    );
    expect(kLowMemoryImageCacheMaxEntries, greaterThanOrEqualTo(1000));
  });
}
