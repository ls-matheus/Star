import 'package:flutter_test/flutter_test.dart';
import 'package:star_app/core/theme/star_layout_theme.dart';
import 'package:star_app/core/theme/star_text_theme.dart';
import 'package:star_app/core/theme/star_theme.dart';
import 'package:star_app/core/theme/themes/dark.dart';
import 'package:star_app/features/ui/accordion/star_accordion.dart';
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
  group('StarAccordion', () {
    testWidgets('shows title text', (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          const StarAccordion(
            title: 'Section Title',
            child: Text('Hidden content'),
          ),
        ),
      );

      expect(find.text('Section Title'), findsOneWidget);
    });

    testWidgets('shows child content when initially expanded', (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          const StarAccordion(
            title: 'Expanded Section',
            initiallyExpanded: true,
            child: Text('Visible content'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Visible content'), findsOneWidget);
      final visibleContentBox = tester.getSize(find.text('Visible content'));
      expect(visibleContentBox.height, greaterThan(0));
    });

    testWidgets('hides child content when collapsed by default', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildTestApp(
          const StarAccordion(
            title: 'Collapsed Section',
            child: Text('Hidden content'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final sizeTransition = tester.widget<SizeTransition>(
        find.byType(SizeTransition),
      );
      expect(sizeTransition.sizeFactor.value, 0.0);
    });

    testWidgets('expands when header is tapped', (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          const StarAccordion(
            title: 'Tap Me',
            child: Text('Expanded content'),
          ),
        ),
      );

      await tester.tap(find.text('Tap Me'));
      await tester.pumpAndSettle();

      final sizeTransition = tester.widget<SizeTransition>(
        find.byType(SizeTransition),
      );
      expect(sizeTransition.sizeFactor.value, 1.0);
    });
  });
}
