import 'package:flutter_test/flutter_test.dart';
import 'package:star_app/core/theme/star_layout_theme.dart';
import 'package:star_app/core/theme/star_text_theme.dart';
import 'package:star_app/core/theme/star_theme.dart';
import 'package:star_app/core/theme/themes/dark.dart';
import 'package:star_app/features/ui/spinner/star_typing_dots.dart';
import 'package:star_app/features/ui/status_indicator/star_typing_status_indicator.dart';
import 'package:star_app/material_ui.dart';
import 'package:visibility_detector/visibility_detector.dart';

import '../../../helpers/test_l10n.dart';

Widget buildTestApp(Widget child) {
  final colorTheme = buildDarkColorTheme();
  return MaterialApp(
    locale: kTestLocale,
    localizationsDelegates: starLocalizationsDelegates,
    supportedLocales: StarLocalizations.supportedLocales,
    theme: buildStarTheme(
      colorTheme: colorTheme,
      textTheme: StarTextTheme.fromColors(colorTheme),
      layoutTheme: StarLayoutTheme.scaled(),
    ),
    home: Scaffold(body: child),
  );
}

Finder _typingPaintFinder() => find.descendant(
  of: find.byType(StarTypingStatusIndicator),
  matching: find.byType(CustomPaint),
);

double _dotsProgress(WidgetTester tester) {
  final CustomPaint paint = tester.widget<CustomPaint>(_typingPaintFinder());
  return (paint.painter! as StarTypingDotsPainter).progress.value;
}

Future<double> _awaitProgress(WidgetTester tester) async {
  final Finder paintFinder = _typingPaintFinder();
  for (int i = 0; i < 20; i++) {
    await tester.pump();
    if (paintFinder.evaluate().isNotEmpty) {
      return _dotsProgress(tester);
    }
  }
  fail('typing indicator painter not found');
}

Widget _wrapPositioned({required bool onScreen}) => buildTestApp(
  ClipRect(
    child: Stack(
      clipBehavior: Clip.none,
      children: <Widget>[
        Positioned(
          left: 0,
          top: onScreen ? 0 : 5000,
          child: const StarTypingStatusIndicator(
            status: 'online',
            width: 22,
            height: 12,
          ),
        ),
      ],
    ),
  ),
);

void main() {
  group('starTypingDotWave', () {
    test('animates left-to-right', () {
      expect(
        starTypingDotWave(0, kStarTypingDotDelays[0]),
        greaterThan(starTypingDotWave(0, kStarTypingDotDelays[2])),
      );
      expect(
        starTypingDotWave(0.6, kStarTypingDotDelays[2]),
        greaterThan(starTypingDotWave(0.6, kStarTypingDotDelays[0])),
      );
    });
  });

  group('StarTypingStatusIndicator', () {
    setUp(() {
      VisibilityDetectorController.instance.updateInterval = Duration.zero;
    });

    tearDown(() {
      VisibilityDetectorController.instance.updateInterval = const Duration(
        milliseconds: 500,
      );
      TestWidgetsFlutterBinding.instance.handleAppLifecycleStateChanged(
        AppLifecycleState.resumed,
      );
    });

    testWidgets('animates dots via CustomPainter without Opacity layers', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildTestApp(
          const StarTypingStatusIndicator(
            status: 'online',
            width: 22,
            height: 12,
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(StarTypingDots), findsOneWidget);
      expect(_typingPaintFinder(), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(StarTypingStatusIndicator),
          matching: find.byType(Opacity),
        ),
        findsNothing,
      );

      final double first = _dotsProgress(tester);
      await tester.pump(const Duration(milliseconds: 600));
      final double second = _dotsProgress(tester);
      expect(second, isNot(first));
    });

    testWidgets('keeps dots inset from the pill edges', (tester) async {
      const double width = 22;
      const double height = 12;
      await tester.pumpWidget(
        buildTestApp(
          const StarTypingStatusIndicator(
            status: 'online',
            width: width,
            height: height,
          ),
        ),
      );
      await tester.pump();

      final Size dotsSize = tester.getSize(find.byType(StarTypingDots));
      expect(dotsSize.width, lessThan(width));
      expect(dotsSize.height, lessThan(height));
    });

    testWidgets('animates dots left-to-right in RTL layouts', (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          const Directionality(
            textDirection: TextDirection.rtl,
            child: StarTypingStatusIndicator(
              status: 'online',
              width: 22,
              height: 12,
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(StarTypingDots), findsOneWidget);
      expect(
        starTypingDotWave(0, kStarTypingDotDelays[0]),
        greaterThan(starTypingDotWave(0, kStarTypingDotDelays[2])),
      );
      expect(
        starTypingDotWave(0.6, kStarTypingDotDelays[2]),
        greaterThan(starTypingDotWave(0.6, kStarTypingDotDelays[0])),
      );
    });

    testWidgets('pauses animation when scrolled offscreen', (tester) async {
      await tester.pumpWidget(_wrapPositioned(onScreen: true));
      final double first = await _awaitProgress(tester);

      await tester.pump(const Duration(milliseconds: 600));
      final double second = _dotsProgress(tester);
      expect(
        second,
        isNot(first),
        reason: 'control: visible typing indicator should animate',
      );

      await tester.pumpWidget(_wrapPositioned(onScreen: false));
      await tester.pump();
      final double frozen = _dotsProgress(tester);

      await tester.pump(const Duration(milliseconds: 600));
      final double afterOffscreen = _dotsProgress(tester);
      expect(
        afterOffscreen,
        frozen,
        reason: 'offscreen typing indicator must freeze',
      );
    });

    testWidgets('pauses animation when app is paused', (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          const StarTypingStatusIndicator(
            status: 'online',
            width: 22,
            height: 12,
          ),
        ),
      );
      await tester.pump();
      final double first = await _awaitProgress(tester);

      await tester.pump(const Duration(milliseconds: 600));
      final double second = _dotsProgress(tester);
      expect(
        second,
        isNot(first),
        reason: 'control: foreground typing indicator should animate',
      );

      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await tester.pump();
      final double frozen = _dotsProgress(tester);

      await tester.pump(const Duration(milliseconds: 600));
      final double afterPause = _dotsProgress(tester);
      expect(
        afterPause,
        frozen,
        reason: 'backgrounded typing indicator must freeze',
      );
    });
  });
}
