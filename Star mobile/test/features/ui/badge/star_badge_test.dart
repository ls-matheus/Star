import 'package:flutter/widgets.dart' as widgets;
import 'package:flutter_test/flutter_test.dart';
import 'package:star_app/core/theme/star_layout_theme.dart';
import 'package:star_app/core/theme/star_text_theme.dart';
import 'package:star_app/core/theme/star_theme.dart';
import 'package:star_app/core/theme/themes/dark.dart';
import 'package:star_app/features/ui/badge/star_badge.dart';
import 'package:star_app/material_ui.dart';

Widget buildTestApp(Widget child, {MediaQueryData? mediaQuery}) {
  final colorTheme = buildDarkColorTheme();
  final Widget app = MaterialApp(
    theme: buildStarTheme(
      colorTheme: colorTheme,
      textTheme: StarTextTheme.fromColors(colorTheme),
      layoutTheme: StarLayoutTheme.scaled(),
    ),
    home: Scaffold(body: Center(child: child)),
  );
  if (mediaQuery == null) {
    return app;
  }
  return MediaQuery(data: mediaQuery, child: app);
}

BoxDecoration _pillDecoration(WidgetTester tester) {
  final Container pill = tester.widget<Container>(
    find.descendant(
      of: find.byType(StarBadge),
      matching: find.byType(Container),
    ),
  );
  return pill.decoration! as BoxDecoration;
}

void main() {
  group('StarBadge', () {
    testWidgets('count variant renders count text', (tester) async {
      await tester.pumpWidget(buildTestApp(const StarBadge.count(count: 5)));

      expect(find.text('5'), findsOneWidget);
    });

    testWidgets('count variant caps at 99+', (tester) async {
      await tester.pumpWidget(
        buildTestApp(const StarBadge.count(count: 150)),
      );

      expect(find.text('99+'), findsOneWidget);
    });

    testWidgets('count badge is a desktop rounded square, not a circle', (
      tester,
    ) async {
      await tester.pumpWidget(buildTestApp(const StarBadge.count(count: 7)));

      final BoxDecoration decoration = _pillDecoration(tester);
      expect(decoration.borderRadius, BorderRadius.circular(6));
      expect(decoration.shape, BoxShape.rectangle);
      expect(decoration.color, buildDarkColorTheme().statusDanger);
      expect(decoration.boxShadow, const <BoxShadow>[
        BoxShadow(
          color: Color(0x1A000000),
          offset: Offset(0, 4),
          blurRadius: 6,
          spreadRadius: -1,
        ),
        BoxShadow(
          color: Color(0x1A000000),
          offset: Offset(0, 2),
          blurRadius: 4,
          spreadRadius: -2,
        ),
      ]);
      expect(tester.getSize(find.byType(StarBadge)).height, 20);
    });

    testWidgets('count text matches desktop size, weight and colour', (
      tester,
    ) async {
      await tester.pumpWidget(buildTestApp(const StarBadge.count(count: 7)));

      final TextStyle style = tester
          .widget<widgets.Text>(find.text('7'))
          .style!;
      expect(style.fontSize, 11);
      expect(style.fontWeight, FontWeight.w600);
      expect(style.color, Colors.white);
    });

    testWidgets('wide counts grow with 6px side padding at 20px tall', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildTestApp(const StarBadge.count(count: 150)),
      );

      final Size badge = tester.getSize(find.byType(StarBadge));
      final Size text = tester.getSize(find.text('99+'));
      expect(badge.height, 20);
      expect(badge.width, text.width + 12);
    });

    testWidgets('digit sits in the centre of the badge', (tester) async {
      await tester.pumpWidget(buildTestApp(const StarBadge.count(count: 3)));

      final Rect badge = tester.getRect(find.byType(StarBadge));
      final Rect text = tester.getRect(find.text('3'));
      expect(badge.width, greaterThanOrEqualTo(20));
      expect(text.center.dx, closeTo(badge.center.dx, 0.01));
      expect(text.center.dy, closeTo(badge.center.dy, 0.01));
    });

    testWidgets('inline badge draws no cutout ring', (tester) async {
      await tester.pumpWidget(buildTestApp(const StarBadge.count(count: 3)));

      expect(_pillDecoration(tester).border, isNull);
      expect(
        find.descendant(
          of: find.byType(StarBadge),
          matching: find.byType(DecoratedBox),
        ),
        findsOneWidget,
      );
    });

    testWidgets('overlay badge rings itself with a 3px cutout outside', (
      tester,
    ) async {
      const Color surface = Color(0xFF121214);
      await tester.pumpWidget(
        buildTestApp(const StarBadge.count(count: 3, cutoutColor: surface)),
      );

      final DecoratedBox ring = tester.widget<DecoratedBox>(
        find
            .descendant(
              of: find.byType(StarBadge),
              matching: find.byType(DecoratedBox),
            )
            .first,
      );
      final BoxDecoration decoration = ring.decoration as BoxDecoration;
      final Border border = decoration.border! as Border;
      expect(border.top.color, surface);
      expect(border.top.width, 3);
      expect(border.top.strokeAlign, BorderSide.strokeAlignOutside);
      expect(decoration.borderRadius, BorderRadius.circular(6));
      expect(decoration.color, isNull);
      expect(_pillDecoration(tester).border, isNull);
      expect(tester.getSize(find.byType(StarBadge)).height, 20);
    });

    testWidgets('digits keep their size at the largest text scale', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildTestApp(
          const StarBadge.count(count: 99),
          mediaQuery: const MediaQueryData(textScaler: TextScaler.linear(3.1)),
        ),
      );

      expect(tester.getSize(find.byType(StarBadge)).height, 20);
      final Size text = tester.getSize(find.text('99'));
      expect(text.height, lessThanOrEqualTo(StarBadge.height));
      expect(tester.takeException(), isNull);
    });

    testWidgets('dot variant renders as small circle', (tester) async {
      await tester.pumpWidget(buildTestApp(const StarBadge.dot()));

      final badge = tester.widget<StarBadge>(find.byType(StarBadge));
      expect(badge.isDot, isTrue);
      expect(badge.size, 8);
    });

    testWidgets('label variant renders arbitrary text', (tester) async {
      await tester.pumpWidget(
        buildTestApp(const StarBadge.label(text: 'NEW')),
      );

      expect(find.text('NEW'), findsOneWidget);
    });
  });

  group('StarBadgeEntrance', () {
    double scaleOf(WidgetTester tester) {
      final Transform transform = tester.widget<Transform>(
        find.descendant(
          of: find.byType(StarBadgeEntrance),
          matching: find.byType(Transform),
        ),
      );
      return transform.transform.storage[0];
    }

    testWidgets('springs in from 0.85 scale', (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          const StarBadgeEntrance(child: StarBadge.count(count: 1)),
        ),
      );

      expect(scaleOf(tester), closeTo(StarBadgeEntrance.initialScale, 0.01));
      await tester.pump(const Duration(milliseconds: 40));
      expect(scaleOf(tester), greaterThan(StarBadgeEntrance.initialScale));
      await tester.pumpAndSettle();
      expect(scaleOf(tester), 1);
    });

    testWidgets('appears at full size when animations are disabled', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildTestApp(
          const StarBadgeEntrance(child: StarBadge.count(count: 1)),
          mediaQuery: const MediaQueryData(disableAnimations: true),
        ),
      );

      expect(scaleOf(tester), 1);
    });
  });
}
