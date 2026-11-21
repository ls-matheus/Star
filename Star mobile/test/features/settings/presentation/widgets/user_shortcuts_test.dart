import 'package:flutter_test/flutter_test.dart';
import 'package:star_app/core/theme/star_layout_theme.dart';
import 'package:star_app/core/theme/star_text_theme.dart';
import 'package:star_app/core/theme/star_theme.dart';
import 'package:star_app/core/theme/themes/dark.dart';
import 'package:star_app/features/settings/presentation/widgets/user_shortcuts.dart';
import 'package:star_app/material_ui.dart';

import '../../../../helpers/test_l10n.dart';

Widget _wrap(Widget child) {
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
  testWidgets('DefaultShortcutsList shows section headings', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        const SingleChildScrollView(
          child: DefaultShortcutsList(searchQuery: ''),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Defaults'), findsOneWidget);
    expect(find.text('Navigation'), findsOneWidget);
  });

  testWidgets('UserShortcuts shows search field', (WidgetTester tester) async {
    await tester.pumpWidget(_wrap(const UserShortcuts()));
    await tester.pumpAndSettle();

    expect(find.text(testL10n.keybindsSearchShortcuts), findsOneWidget);
  });
}
