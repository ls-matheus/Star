import 'package:flutter_test/flutter_test.dart';
import 'package:star_app/core/theme/star_layout_theme.dart';
import 'package:star_app/core/theme/star_text_theme.dart';
import 'package:star_app/core/theme/star_theme.dart';
import 'package:star_app/core/theme/themes/dark.dart';
import 'package:star_app/features/channels/domain/channel.dart';
import 'package:star_app/features/channels/presentation/widgets/channel_icon.dart';
import 'package:star_app/features/chat/presentation/widgets/messages/channel_welcome_section.dart';
import 'package:star_app/material_ui.dart';

import '../../../../../helpers/test_l10n.dart';

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
  testWidgets('renders the channel name as the heading above the body', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        const ChannelWelcomeSection(
          channel: Channel(
            id: 'channel-1',
            guildId: 'guild-1',
            name: 'general',
          ),
        ),
      ),
    );

    expect(find.text('#general'), findsOneWidget);
    expect(
      find.text('There are no older messages in #general.'),
      findsOneWidget,
    );
    expect(find.textContaining('Welcome'), findsNothing);
    expect(find.byType(ChannelIcon), findsNothing);
  });

  testWidgets('clips combining marks in the heading and body', (tester) async {
    const String zalgo = 'à̶́̂̃̄̅̕';
    await tester.pumpWidget(
      _app(
        const ChannelWelcomeSection(
          channel: Channel(id: 'channel-1', guildId: 'guild-1', name: zalgo),
        ),
      ),
    );

    for (final String text in <String>[
      '#$zalgo',
      testL10n.channelWelcomeDescription('#$zalgo'),
    ]) {
      expect(
        find.ancestor(of: find.text(text), matching: find.byType(ClipRect)),
        findsWidgets,
      );
    }
  });
}
