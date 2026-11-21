import 'package:flutter_test/flutter_test.dart';
import 'package:star_app/core/theme/star_layout_theme.dart';
import 'package:star_app/core/theme/star_text_theme.dart';
import 'package:star_app/core/theme/star_theme.dart';
import 'package:star_app/core/theme/themes/dark.dart';
import 'package:star_app/features/chat/domain/composer_slash_command.dart';
import 'package:star_app/features/chat/presentation/widgets/composer/slash_command_param_bar.dart';
import 'package:star_app/features/chat/presentation/widgets/composer/wide_composer_layout.dart';
import 'package:star_app/features/chat/services/composer_slash_session.dart';
import 'package:star_app/material_ui.dart';

import '../../../../../helpers/test_l10n.dart';

void main() {
  testWidgets('param bar shows the focused option name and description', (
    tester,
  ) async {
    final ComposerSlashSession session = ComposerSlashSession();
    addTearDown(session.dispose);
    session.start(
      const ComposerActionSlashCommand(
        name: '/kick',
        description: 'd',
        options: <ComposerCommandOption>[
          ComposerCommandOption(
            name: 'user',
            description: 'User to kick',
            type: ComposerCommandOptionType.user,
            required: true,
          ),
        ],
      ),
    );

    final colorTheme = buildDarkColorTheme();
    await tester.pumpWidget(
      MaterialApp(
        locale: kTestLocale,
        localizationsDelegates: starLocalizationsDelegates,
        supportedLocales: StarLocalizations.supportedLocales,
        theme: buildStarTheme(
          colorTheme: colorTheme,
          textTheme: StarTextTheme.fromColors(colorTheme),
          layoutTheme: StarLayoutTheme.scaled(),
        ),
        home: Scaffold(
          body: SlashCommandParamBar(session: session, onClear: () {}),
        ),
      ),
    );

    expect(find.text('user'), findsOneWidget);
    expect(find.text('User to kick'), findsOneWidget);
    expect(
      tester.getSize(find.byType(SlashCommandParamBar)).height,
      WideComposerLayout.actionRowMinHeight,
    );
  });
}
