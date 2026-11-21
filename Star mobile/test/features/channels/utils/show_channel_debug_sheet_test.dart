import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:star_app/core/database/star_database.dart'
    show StarDatabase;
import 'package:star_app/core/providers/database_provider.dart';
import 'package:star_app/core/theme/star_layout_theme.dart';
import 'package:star_app/core/theme/star_text_theme.dart';
import 'package:star_app/core/theme/star_theme.dart';
import 'package:star_app/core/theme/themes/dark.dart';
import 'package:star_app/features/channels/domain/channel.dart';
import 'package:star_app/features/channels/utils/show_channel_debug_sheet.dart';
import 'package:star_app/material_ui.dart';

import '../../../helpers/open_test_database.dart';
import '../../../helpers/test_l10n.dart';

void main() {
  Future<String> openDebugSheet(
    WidgetTester tester, {
    required String channelId,
    required Future<void> Function(StarDatabase db) seed,
  }) async {
    final db = openTestDatabase();
    await seed(db);

    final colorTheme = buildDarkColorTheme();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [starDatabaseProvider.overrideWithValue(db)],
        child: MaterialApp(
          locale: kTestLocale,
          localizationsDelegates: starLocalizationsDelegates,
          supportedLocales: StarLocalizations.supportedLocales,
          theme: buildStarTheme(
            colorTheme: colorTheme,
            textTheme: StarTextTheme.fromColors(colorTheme),
            layoutTheme: StarLayoutTheme.scaled(),
          ),
          home: Consumer(
            builder: (context, ref, _) => Scaffold(
              body: Center(
                child: TextButton(
                  onPressed: () => showChannelDebugSheet(
                    context,
                    ref: ref,
                    channelId: channelId,
                    title: 'Channel Debug',
                  ),
                  child: const Text('open'),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    return tester.widget<SelectableText>(find.byType(SelectableText)).data;
  }

  testWidgets('renders the voice channel record as wire-format JSON', (
    tester,
  ) async {
    final json = await openDebugSheet(
      tester,
      channelId: 'voice-1',
      seed: (db) => db.channelDao.upsertChannels([
        const Channel(
          id: 'voice-1',
          guildId: 'g1',
          name: 'voice-room',
          type: ChannelType.guildVoice,
          userLimit: 5,
        ).toCompanion(),
      ]),
    );

    expect(json, contains('"id": "voice-1"'));
    expect(json, contains('"guild_id": "g1"'));
    expect(json, contains('"type": ${ChannelType.guildVoice.wireValue}'));
    expect(json, contains('"user_limit": 5'));
    expect(json, isNot(contains('guildId')));
  });

  testWidgets('renders the link channel record as wire-format JSON', (
    tester,
  ) async {
    final json = await openDebugSheet(
      tester,
      channelId: 'link-1',
      seed: (db) => db.channelDao.upsertChannels([
        const Channel(
          id: 'link-1',
          guildId: 'g1',
          name: 'link-out',
          url: 'https://example.com',
          type: ChannelType.guildLink,
        ).toCompanion(),
      ]),
    );

    expect(json, contains('"id": "link-1"'));
    expect(json, contains('"url": "https://example.com"'));
    expect(json, contains('"type": ${ChannelType.guildLink.wireValue}'));
  });
}
