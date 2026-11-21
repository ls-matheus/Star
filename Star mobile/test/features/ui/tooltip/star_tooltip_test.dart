import 'package:flutter_test/flutter_test.dart';
import 'package:star_app/core/theme/star_layout_theme.dart';
import 'package:star_app/core/theme/star_text_theme.dart';
import 'package:star_app/core/theme/star_theme.dart';
import 'package:star_app/core/theme/themes/dark.dart';
import 'package:star_app/features/ui/tooltip/star_tooltip.dart';
import 'package:star_app/material_ui.dart';

Widget buildTestApp(Widget child) {
  final colorTheme = buildDarkColorTheme();
  return MaterialApp(
    theme: buildStarTheme(
      colorTheme: colorTheme,
      textTheme: StarTextTheme.fromColors(colorTheme),
      layoutTheme: StarLayoutTheme.scaled(),
    ),
    home: Scaffold(body: child),
  );
}

void main() {
  group('StarTooltip', () {
    testWidgets('renders child widget', (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          const StarTooltip(message: 'Tooltip text', child: Text('Child')),
        ),
      );

      expect(find.text('Child'), findsOneWidget);
    });

    testWidgets('does not show tooltip initially', (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          const StarTooltip(message: 'Tooltip text', child: Text('Child')),
        ),
      );

      expect(find.text('Tooltip text'), findsNothing);
    });

    testWidgets('shows tooltip message on long press', (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          const StarTooltip(
            message: 'Tooltip text',
            child: SizedBox(width: 100, height: 100),
          ),
        ),
      );

      await tester.longPress(find.byType(StarTooltip));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Tooltip text'), findsOneWidget);
    });

    testWidgets('exposes message as semantics label', (tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();

      await tester.pumpWidget(
        buildTestApp(
          const StarTooltip(
            message: 'Open settings',
            child: SizedBox(width: 40, height: 40),
          ),
        ),
      );

      expect(find.bySemanticsLabel('Open settings'), findsOneWidget);
      handle.dispose();
    });

    testWidgets('keeps long tooltip on screen near the right edge', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        buildTestApp(
          const Align(
            alignment: Alignment.bottomRight,
            child: Padding(
              padding: EdgeInsets.only(right: 8, bottom: 40),
              child: StarTooltip(
                message: 'Slowmode is set to 30s for this channel.',
                child: Text('Slowmode is enabled'),
              ),
            ),
          ),
        ),
      );

      await tester.longPress(find.text('Slowmode is enabled'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      final Rect tooltipRect = tester.getRect(
        find.text('Slowmode is set to 30s for this channel.'),
      );
      expect(tooltipRect.left, greaterThanOrEqualTo(8));
      expect(tooltipRect.right, lessThanOrEqualTo(312));
      expect(tooltipRect.top, greaterThanOrEqualTo(8));
      expect(tooltipRect.bottom, lessThanOrEqualTo(632));
    });
  });
}
