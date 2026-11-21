import 'package:flutter_test/flutter_test.dart';
import 'package:star_app/core/theme/star_layout_theme.dart';
import 'package:star_app/core/theme/star_text_theme.dart';
import 'package:star_app/core/theme/star_theme.dart';
import 'package:star_app/core/theme/themes/dark.dart';
import 'package:star_app/features/chat/presentation/widgets/pickers/emoji_search_bar.dart';
import 'package:star_app/material_ui.dart';
import 'package:star_app/shared/widgets/unicode_emoji_widget.dart';

import '../../../../../helpers/test_l10n.dart';

const String _kClapEmoji = '\u{1F44F}';

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
  testWidgets('skin tone preview renders with UnicodeEmojiWidget', (
    tester,
  ) async {
    final controller = TextEditingController();
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      buildTestApp(
        EmojiSearchBar(
          controller: controller,
          skinTone: kSkinToneSurrogates[2],
          onSkinToneChanged: (_) {},
        ),
      ),
    );
    await tester.pump();

    expect(find.byType(UnicodeEmojiWidget), findsOneWidget);
    expect(find.text(_kClapEmoji + kSkinToneSurrogates[2]), findsNothing);
  });
}
