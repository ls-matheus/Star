import 'package:flutter_test/flutter_test.dart';
import 'package:star_app/core/theme/star_layout_theme.dart';
import 'package:star_app/core/theme/star_text_theme.dart';
import 'package:star_app/core/theme/star_theme.dart';
import 'package:star_app/core/theme/themes/dark.dart';
import 'package:star_app/features/chat/presentation/widgets/composer/composer_autocomplete_field.dart';
import 'package:star_app/l10n/star_localizations_delegates.dart';
import 'package:star_app/l10n/generated/star_localizations.dart';
import 'package:star_app/material_ui.dart';
import 'package:star_app/shared/widgets/unicode_emoji_widget.dart';

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
  testWidgets(
    'emoji autocomplete row renders the emoji preview and its source label',
    (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          ComposerAutocompletePanelListTile(
            title: ':monkey:',
            subtitle: 'Linux Hub',
            isSelected: false,
            onTap: () {},
            emojiSurrogates: '🐒',
          ),
        ),
      );

      expect(find.text(':monkey:'), findsOneWidget);
      expect(find.byType(UnicodeEmojiWidget), findsOneWidget);
      expect(find.text('Linux Hub'), findsOneWidget);
    },
  );
}
