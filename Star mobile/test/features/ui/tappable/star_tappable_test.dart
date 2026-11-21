import 'package:flutter_test/flutter_test.dart';
import 'package:star_app/core/theme/star_layout_theme.dart';
import 'package:star_app/core/theme/star_text_theme.dart';
import 'package:star_app/core/theme/star_theme.dart';
import 'package:star_app/core/theme/themes/dark.dart';
import 'package:star_app/features/ui/tappable/star_tappable.dart';
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
  group('StarTappable', () {
    testWidgets('calls onTap when tapped', (tester) async {
      var tapped = false;
      await tester.pumpWidget(
        buildTestApp(
          StarTappable(
            onTap: () => tapped = true,
            builder: (context, states) =>
                const SizedBox(width: 100, height: 100),
          ),
        ),
      );

      await tester.tap(find.byType(StarTappable));
      expect(tapped, isTrue);
    });

    testWidgets('does not call onTap when disabled', (tester) async {
      var tapped = false;
      await tester.pumpWidget(
        buildTestApp(
          StarTappable(
            onTap: () => tapped = true,
            enabled: false,
            builder: (context, states) =>
                const SizedBox(width: 100, height: 100),
          ),
        ),
      );

      await tester.tap(find.byType(StarTappable));
      expect(tapped, isFalse);
    });

    testWidgets('exposes disabled state when enabled is false', (tester) async {
      Set<WidgetState>? capturedStates;
      await tester.pumpWidget(
        buildTestApp(
          StarTappable(
            onTap: () {},
            enabled: false,
            builder: (context, states) {
              capturedStates = states;
              return const SizedBox(width: 100, height: 100);
            },
          ),
        ),
      );

      expect(capturedStates, contains(WidgetState.disabled));
    });

    testWidgets('shows click cursor when enabled', (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          StarTappable(
            onTap: () {},
            builder: (context, states) =>
                const SizedBox(width: 100, height: 100),
          ),
        ),
      );

      final mouseRegion = tester.widget<MouseRegion>(
        find.descendant(
          of: find.byType(StarTappable),
          matching: find.byType(MouseRegion),
        ),
      );
      expect(mouseRegion.cursor, SystemMouseCursors.click);
    });

    testWidgets('shows basic cursor when disabled', (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          StarTappable(
            onTap: () {},
            enabled: false,
            builder: (context, states) =>
                const SizedBox(width: 100, height: 100),
          ),
        ),
      );

      final mouseRegion = tester.widget<MouseRegion>(
        find.descendant(
          of: find.byType(StarTappable),
          matching: find.byType(MouseRegion),
        ),
      );
      expect(mouseRegion.cursor, SystemMouseCursors.basic);
    });

    testWidgets('calls onLongPress when long-pressed', (tester) async {
      var longPressed = false;
      await tester.pumpWidget(
        buildTestApp(
          StarTappable(
            onLongPress: () => longPressed = true,
            builder: (context, states) =>
                const SizedBox(width: 100, height: 100),
          ),
        ),
      );

      await tester.longPress(find.byType(StarTappable));
      expect(longPressed, isTrue);
    });

    testWidgets('has reduced opacity when disabled', (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          StarTappable(
            onTap: () {},
            enabled: false,
            builder: (context, states) =>
                const SizedBox(width: 100, height: 100),
          ),
        ),
      );

      final animatedOpacity = tester.widget<AnimatedOpacity>(
        find.byType(AnimatedOpacity),
      );
      expect(animatedOpacity.opacity, 0.5);
    });

    testWidgets('exposes selected state and minimum hit target when provided', (
      tester,
    ) async {
      Set<WidgetState>? capturedStates;

      await tester.pumpWidget(
        buildTestApp(
          StarTappable(
            onTap: () {},
            selected: true,
            minSize: const Size(48, 52),
            builder: (context, states) {
              capturedStates = states;
              return const SizedBox(width: 8, height: 8);
            },
          ),
        ),
      );

      expect(capturedStates, contains(WidgetState.selected));

      final constrainedBox = tester.widget<ConstrainedBox>(
        find.descendant(
          of: find.byType(StarTappable),
          matching: find.byType(ConstrainedBox),
        ),
      );
      expect(constrainedBox.constraints.minWidth, 48);
      expect(constrainedBox.constraints.minHeight, 52);
    });

    testWidgets('exposes semanticLabel and tap action', (tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      var tapped = false;

      await tester.pumpWidget(
        buildTestApp(
          StarTappable(
            onTap: () => tapped = true,
            semanticLabel: 'Open menu',
            builder: (context, states) =>
                const SizedBox(width: 100, height: 100),
          ),
        ),
      );

      expect(find.bySemanticsLabel('Open menu'), findsOneWidget);
      await tester.tap(find.bySemanticsLabel('Open menu'));
      expect(tapped, isTrue);
      handle.dispose();
    });
  });
}
