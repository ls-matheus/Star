import 'package:flutter_test/flutter_test.dart';
import 'package:star_app/core/theme/star_layout_theme.dart';
import 'package:star_app/core/theme/star_text_theme.dart';
import 'package:star_app/core/theme/star_theme.dart';
import 'package:star_app/core/theme/themes/dark.dart';
import 'package:star_app/features/chat/domain/message_translation.dart';
import 'package:star_app/features/chat/presentation/widgets/messages/message_translation_indicator.dart';
import 'package:star_app/material_ui.dart';
import 'package:star_app/shared/icons/phosphor.dart';

import '../../../../../helpers/test_l10n.dart';

const MessageTranslation _translation = MessageTranslation(
  translatedContent: 'Hello world',
  sourceLanguageCode: 'de',
  sourceContent: 'Hallo Welt',
  targetLanguageCode: 'en',
);

Widget _app(Widget child) {
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
  testWidgets('shows translated-from copy and see original', (tester) async {
    await tester.pumpWidget(
      _app(
        const MessageTranslationIndicator(
          translation: _translation,
          onToggleOriginal: _noop,
        ),
      ),
    );

    expect(find.textContaining('Translated from German'), findsOneWidget);
    expect(find.text(testL10n.chatMessageSeeOriginal), findsOneWidget);
    expect(find.byType(PhosphorIcon), findsOneWidget);
  });

  testWidgets('tapping see original invokes the toggle', (tester) async {
    var tapped = false;
    await tester.pumpWidget(
      _app(
        MessageTranslationIndicator(
          translation: _translation,
          onToggleOriginal: () => tapped = true,
        ),
      ),
    );

    await tester.tap(find.text(testL10n.chatMessageSeeOriginal));
    expect(tapped, isTrue);
  });

  testWidgets('shows see translation when viewing the original', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        MessageTranslationIndicator(
          translation: _translation.copyWith(showOriginal: true),
          onToggleOriginal: _noop,
        ),
      ),
    );

    expect(find.text(testL10n.chatMessageSeeTranslation), findsOneWidget);
    expect(find.text(testL10n.chatMessageSeeOriginal), findsNothing);
  });

  testWidgets('shows translating copy with a translate icon', (tester) async {
    await tester.pumpWidget(_app(const MessageTranslatingIndicator()));

    expect(find.text(testL10n.chatMessageTranslating), findsOneWidget);
    expect(find.byType(PhosphorIcon), findsOneWidget);
  });
}

void _noop() {}
