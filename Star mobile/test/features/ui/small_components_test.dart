import 'package:flutter_test/flutter_test.dart';
import 'package:star_app/core/theme/star_layout_theme.dart';
import 'package:star_app/core/theme/star_text_theme.dart';
import 'package:star_app/core/theme/star_theme.dart';
import 'package:star_app/core/theme/themes/dark.dart';
import 'package:star_app/features/ui/character_counter/star_character_counter.dart';
import 'package:star_app/features/ui/keybind_hint/star_keybind_hint.dart';
import 'package:star_app/features/ui/scroller/star_scroller.dart';
import 'package:star_app/features/ui/warning_alert/star_warning_alert.dart';
import 'package:star_app/l10n/star_localizations_delegates.dart';
import 'package:star_app/l10n/generated/star_localizations.dart';
import 'package:star_app/material_ui.dart';

import '../../helpers/rendered_text_test_helpers.dart';

Widget buildTestApp(Widget child) {
  final colorTheme = buildDarkColorTheme();
  return MaterialApp(
    theme: buildStarTheme(
      colorTheme: colorTheme,
      textTheme: StarTextTheme.fromColors(colorTheme),
      layoutTheme: StarLayoutTheme.scaled(),
    ),
    localizationsDelegates: starLocalizationsDelegates,
    supportedLocales: StarLocalizations.supportedLocales,
    home: Scaffold(body: child),
  );
}

void main() {
  group('StarCharacterCounter', () {
    testWidgets('shows remaining characters', (tester) async {
      await tester.pumpWidget(
        buildTestApp(const StarCharacterCounter(current: 42, max: 200)),
      );

      expect(find.text('158'), findsOneWidget);
    });

    testWidgets('uses danger color when nearing limit', (tester) async {
      await tester.pumpWidget(
        buildTestApp(const StarCharacterCounter(current: 160, max: 200)),
      );

      final Text text = tester.widget<Text>(findAppText('40'));
      expect(text.style?.color, buildDarkColorTheme().statusDanger);
    });

    testWidgets('shows negative remaining when over limit', (tester) async {
      await tester.pumpWidget(
        buildTestApp(const StarCharacterCounter(current: 250, max: 200)),
      );

      expect(find.text('-50'), findsOneWidget);
    });
  });

  group('StarWarningAlert', () {
    testWidgets('shows message text', (tester) async {
      await tester.pumpWidget(
        buildTestApp(const StarWarningAlert(message: 'Something went wrong')),
      );

      expect(find.text('Something went wrong'), findsOneWidget);
    });

    testWidgets('renders all variants', (tester) async {
      for (final variant in StarAlertVariant.values) {
        await tester.pumpWidget(
          buildTestApp(
            StarWarningAlert(message: 'Test $variant', variant: variant),
          ),
        );

        expect(find.text('Test $variant'), findsOneWidget);
      }
    });
  });

  group('StarKeybindHint', () {
    testWidgets('renders all keys', (tester) async {
      await tester.pumpWidget(
        buildTestApp(const StarKeybindHint(keys: ['Ctrl', 'Shift', 'P'])),
      );

      expect(find.text('Ctrl'), findsOneWidget);
      expect(find.text('Shift'), findsOneWidget);
      expect(find.text('P'), findsOneWidget);
      expect(find.text('+'), findsNothing);
    });

    testWidgets('renders single key without separator', (tester) async {
      await tester.pumpWidget(
        buildTestApp(const StarKeybindHint(keys: ['Esc'])),
      );

      expect(find.text('Esc'), findsOneWidget);
      expect(find.text('+'), findsNothing);
    });
  });

  group('StarScroller', () {
    testWidgets('renders child', (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          SizedBox(
            height: 120,
            child: StarScroller(
              child: ListView(
                children: List.generate(
                  20,
                  (int i) => SizedBox(height: 40, child: Text('Row $i')),
                ),
              ),
            ),
          ),
        ),
      );

      expect(find.text('Row 0'), findsOneWidget);
      await tester.pumpAndSettle();
      expect(find.byType(StarScroller), findsOneWidget);
    });

    testWidgets('uses provided controller', (tester) async {
      final controller = ScrollController();
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        buildTestApp(
          SizedBox(
            height: 200,
            child: StarScroller(
              controller: controller,
              child: ListView.builder(
                controller: controller,
                itemCount: 100,
                itemBuilder: (context, index) => Text('Item $index'),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(StarScroller), findsOneWidget);
    });
  });
}
