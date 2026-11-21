import 'package:flutter_test/flutter_test.dart';
import 'package:star_app/core/theme/star_layout_theme.dart';
import 'package:star_app/core/theme/star_text_theme.dart';
import 'package:star_app/core/theme/star_theme.dart';
import 'package:star_app/core/theme/themes/dark.dart';
import 'package:star_app/features/ui/focus_ring/star_focus_ring.dart';
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
  group('StarFocusRing', () {
    testWidgets('renders child', (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          const StarFocusRing(focused: false, child: Text('Hello')),
        ),
      );

      expect(find.text('Hello'), findsOneWidget);
    });

    testWidgets('shows border when focused', (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          const StarFocusRing(
            focused: true,
            child: SizedBox(width: 100, height: 100),
          ),
        ),
      );

      final container = tester.widget<AnimatedContainer>(
        find.byType(AnimatedContainer),
      );
      final decoration = container.decoration! as BoxDecoration;

      expect(decoration.border, isNull);
      expect(decoration.boxShadow, isNotEmpty);
    });

    testWidgets('hides border when not focused', (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          const StarFocusRing(
            focused: false,
            child: SizedBox(width: 100, height: 100),
          ),
        ),
      );

      final container = tester.widget<AnimatedContainer>(
        find.byType(AnimatedContainer),
      );
      final decoration = container.decoration! as BoxDecoration;

      expect(decoration.border, isNull);
      expect(decoration.boxShadow, isEmpty);
    });
  });
}
