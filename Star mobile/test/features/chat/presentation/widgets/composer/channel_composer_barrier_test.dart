import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:star_app/core/theme/star_color_theme.dart';
import 'package:star_app/core/theme/star_layout_theme.dart';
import 'package:star_app/core/theme/star_text_theme.dart';
import 'package:star_app/core/theme/star_theme.dart';
import 'package:star_app/core/theme/themes/dark.dart';
import 'package:star_app/features/chat/presentation/widgets/composer/channel_composer_barrier.dart';
import 'package:star_app/features/guilds/services/guild_verification.dart';
import 'package:star_app/material_ui.dart';

import '../../../../../helpers/test_l10n.dart';

Widget _barrierTestApp() {
  final StarColorTheme colorTheme = buildDarkColorTheme();
  return ProviderScope(
    child: MaterialApp(
      locale: kTestLocale,
      localizationsDelegates: starLocalizationsDelegates,
      supportedLocales: StarLocalizations.supportedLocales,
      theme: buildStarTheme(
        colorTheme: colorTheme,
        textTheme: StarTextTheme.fromColors(colorTheme),
        layoutTheme: StarLayoutTheme.scaled(),
      ),
      home: const Scaffold(
        body: ChannelComposerBarrier(
          access: GuildComposerAccess(
            canAccess: false,
            reason: GuildComposerBlockReason.guildSendDisabled,
          ),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('shows guild send disabled barrier copy', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(_barrierTestApp());
    expect(
      find.text('Messaging is temporarily paused in this community.'),
      findsOneWidget,
    );
  });
}
