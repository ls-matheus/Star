import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:star_app/features/ui/scroller/star_smooth_scrollbar_metrics.dart';

void main() {
  group('starSmoothScrollbarThumbExtent', () {
    test('shrinks as the scrollable range grows', () {
      const double trackLength = 400;
      const double viewportDimension = 400;
      final double shortList = starSmoothScrollbarThumbExtent(
        trackLength: trackLength,
        viewportDimension: viewportDimension,
        scrollableExtent: 200,
      );
      final double longList = starSmoothScrollbarThumbExtent(
        trackLength: trackLength,
        viewportDimension: viewportDimension,
        scrollableExtent: 4000,
      );
      expect(shortList, greaterThan(longList));
      expect(
        longList,
        greaterThanOrEqualTo(kStarSmoothScrollbarMinThumbExtent),
      );
    });

    test('fills the track when there is nothing to scroll', () {
      expect(
        starSmoothScrollbarThumbExtent(
          trackLength: 200,
          viewportDimension: 200,
          scrollableExtent: 0,
        ),
        200,
      );
    });
  });

  group('starSmoothScrollbarLerpExtent', () {
    test('moves gradually toward target', () {
      final double next = starSmoothScrollbarLerpExtent(
        current: 100,
        target: 500,
        snap: false,
      );
      expect(next, greaterThan(100));
      expect(next, lessThan(500));
    });

    test('snaps immediately', () {
      expect(
        starSmoothScrollbarLerpExtent(current: 100, target: 500, snap: true),
        500,
      );
    });
  });

  group('starSmoothScrollbarScrollFraction', () {
    test('pins to trailing edge', () {
      expect(
        starSmoothScrollbarScrollFraction(
          pixels: 10,
          minExtent: -4000,
          maxExtent: 40,
          pinTrailingEdge: true,
        ),
        1,
      );
    });

    test('uses the full extent range', () {
      expect(
        starSmoothScrollbarScrollFraction(
          pixels: 50,
          minExtent: 0,
          maxExtent: 100,
          pinTrailingEdge: false,
        ),
        0.5,
      );
    });

    test('a small step off the trailing edge stays near the trailing edge', () {
      final double fraction = starSmoothScrollbarScrollFraction(
        pixels: 0,
        minExtent: -8000,
        maxExtent: 40,
        pinTrailingEdge: false,
      );
      expect(fraction, greaterThan(0.95));
    });
  });

  group('starSmoothScrollbarPaintMetrics', () {
    FixedScrollMetrics source({
      required double pixels,
      required double min,
      required double max,
    }) {
      return FixedScrollMetrics(
        minScrollExtent: min,
        maxScrollExtent: max,
        pixels: pixels,
        viewportDimension: 300,
        axisDirection: AxisDirection.down,
        devicePixelRatio: 1,
      );
    }

    test('keeps the real scroll fraction with a smoothed range', () {
      final FixedScrollMetrics metrics = starSmoothScrollbarPaintMetrics(
        source: source(pixels: 250, min: 0, max: 1000),
        smoothedMinScrollExtent: 0,
        smoothedMaxScrollExtent: 2000,
        pinTrailingEdge: false,
      )!;
      expect(metrics.pixels, 500);
      expect(metrics.maxScrollExtent, 2000);
    });

    test('uses real metrics while overscrolling', () {
      final FixedScrollMetrics metrics = starSmoothScrollbarPaintMetrics(
        source: source(pixels: 1100, min: 0, max: 1000),
        smoothedMinScrollExtent: 0,
        smoothedMaxScrollExtent: 2000,
        pinTrailingEdge: false,
      )!;
      expect(metrics.pixels, 1100);
      expect(metrics.maxScrollExtent, 1000);
    });

    test('pins the thumb to the trailing edge', () {
      final FixedScrollMetrics metrics = starSmoothScrollbarPaintMetrics(
        source: source(pixels: 10, min: -4000, max: 40),
        smoothedMinScrollExtent: -5000,
        smoothedMaxScrollExtent: 80,
        pinTrailingEdge: true,
      )!;
      expect(metrics.pixels, metrics.maxScrollExtent);
    });
  });
}
