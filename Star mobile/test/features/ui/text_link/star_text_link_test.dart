import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:star_app/core/theme/star_layout_theme.dart';
import 'package:star_app/core/theme/star_text_theme.dart';
import 'package:star_app/core/theme/star_theme.dart';
import 'package:star_app/core/theme/themes/dark.dart';
import 'package:star_app/features/ui/text_link/star_text_link.dart';
import 'package:star_app/material_ui.dart';

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

void main() {
  group('StarTextLink', () {
    testWidgets('renders text content', (tester) async {
      await tester.pumpWidget(
        buildTestApp(const StarTextLink(text: 'Visit site')),
      );

      expect(find.text('Visit site'), findsOneWidget);
    });

    testWidgets('calls onTap when tapped', (tester) async {
      var tapped = false;
      await tester.pumpWidget(
        buildTestApp(
          StarTextLink(text: 'Click me', onTap: () => tapped = true),
        ),
      );

      await tester.tap(find.text('Click me'));
      expect(tapped, isTrue);
    });

    testWidgets('renders selectable text when selectable is true', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildTestApp(
          const StarTextLink(text: 'Selectable link', selectable: true),
        ),
      );

      expect(find.byType(SelectableText), findsOneWidget);
      expect(find.text('Selectable link'), findsOneWidget);
    });

    testWidgets('has link semantics without duplicate button role', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildTestApp(
          const StarTextLink(text: 'A link', url: 'https://example.com'),
        ),
      );

      final SemanticsNode node = tester.getSemantics(find.text('A link'));
      expect(node.flagsCollection.isLink, isTrue);
      expect(node.flagsCollection.isButton, isFalse);
    });
  });
}
