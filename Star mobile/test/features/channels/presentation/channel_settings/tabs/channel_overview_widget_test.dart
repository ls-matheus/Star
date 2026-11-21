import 'dart:ui' show CheckedState;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:star_app/core/database/star_database.dart'
    show StarDatabase;
import 'package:star_app/core/permissions/permission.dart';
import 'package:star_app/core/providers/database_provider.dart';
import 'package:star_app/core/theme/star_layout_theme.dart';
import 'package:star_app/core/theme/star_text_theme.dart';
import 'package:star_app/core/theme/star_theme.dart';
import 'package:star_app/core/theme/themes/dark.dart';
import 'package:star_app/features/channels/domain/channel.dart';
import 'package:star_app/features/channels/presentation/channel_settings/tabs/channel_overview_widget.dart';
import 'package:star_app/features/channels/providers/channel_settings_providers.dart';
import 'package:star_app/features/guilds/domain/guild.dart';
import 'package:star_app/features/guilds/providers/guild_providers.dart';
import 'package:star_app/material_ui.dart';
import 'package:star_dart/export.dart' hide ChannelType;
import 'package:riverpod/src/framework.dart' show Override;

import '../../../../../helpers/open_test_database.dart';
import '../../../../../helpers/test_l10n.dart';

late StarDatabase _database;

void main() {
  setUp(() {
    _database = openTestDatabase();
  });

  const String guildId = 'guild-1';
  const Channel textChannel = Channel(
    id: 'text-1',
    guildId: guildId,
    name: 'general',
  );
  const Channel categoryChannel = Channel(
    id: 'cat-1',
    guildId: guildId,
    name: 'Category',
    type: ChannelType.guildCategory,
    nsfwOverride: true,
  );
  const Channel voiceChannel = Channel(
    id: 'voice-1',
    guildId: guildId,
    name: 'voice',
    type: ChannelType.guildVoice,
    bitrate: 64000,
  );
  const Channel linkChannel = Channel(
    id: 'link-1',
    guildId: guildId,
    name: 'links',
    type: ChannelType.guildLink,
    url: 'https://example.com',
  );

  testWidgets('text channel shows messaging fields', (tester) async {
    await _pumpTestApp(
      tester,
      child: ChannelOverviewWidget(
        channel: textChannel,
        permissions: Permission.manageChannels.value,
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Channel name'), findsOneWidget);
    expect(find.text('Topic'), findsOneWidget);
    expect(find.text('Slowmode'), findsOneWidget);
    expect(find.text('URL'), findsNothing);
    expect(find.text('Voice quality'), findsNothing);
  });

  testWidgets('voice channel shows voice fields', (tester) async {
    await _pumpTestApp(
      tester,
      overrides: <Override>[
        channelRtcRegionsProvider(voiceChannel.id).overrideWith(
          (Ref ref) => <RtcRegionResponse>[
            const RtcRegionResponse(
              id: 'us-east',
              name: 'US East',
              emoji: '🇺🇸',
            ),
          ],
        ),
      ],
      child: ChannelOverviewWidget(
        channel: voiceChannel,
        permissions: Permission.manageChannels.value,
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Voice quality'), findsOneWidget);
    expect(find.text('Participant limit'), findsOneWidget);
  });

  testWidgets('link channel shows URL field', (tester) async {
    await _pumpTestApp(
      tester,
      child: ChannelOverviewWidget(
        channel: linkChannel,
        permissions: Permission.manageChannels.value,
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('URL'), findsOneWidget);
    expect(find.text('Topic'), findsNothing);
  });

  testWidgets('category mature content inherit selection updates radio', (
    tester,
  ) async {
    const Guild guild = Guild(id: guildId, name: 'Test Guild');
    await _pumpTestApp(
      tester,
      overrides: <Override>[
        guildByIdProvider(guildId).overrideWith((Ref ref) => guild),
      ],
      child: ChannelOverviewWidget(
        channel: categoryChannel,
        permissions: Permission.manageChannels.value,
      ),
    );
    await tester.pumpAndSettle();

    final SemanticsHandle handle = tester.ensureSemantics();
    try {
      expect(
        tester
            .getSemantics(find.text('On'))
            .getSemanticsData()
            .flagsCollection
            .isChecked,
        CheckedState.isTrue,
      );

      await tester.tap(find.text('Inherit'));
      await tester.pumpAndSettle();

      expect(
        tester
            .getSemantics(find.text('Inherit'))
            .getSemanticsData()
            .flagsCollection
            .isChecked,
        CheckedState.isTrue,
      );
      expect(
        tester
            .getSemantics(find.text('On'))
            .getSemanticsData()
            .flagsCollection
            .isChecked,
        CheckedState.isFalse,
      );
    } finally {
      handle.dispose();
    }
  });
}

Future<void> _pumpTestApp(
  WidgetTester tester, {
  required Widget child,
  List<Override> overrides = const <Override>[],
}) {
  final colorTheme = buildDarkColorTheme();
  return tester.pumpWidget(
    ProviderScope(
      overrides: <Override>[
        starDatabaseProvider.overrideWithValue(_database),
        ...overrides,
      ],
      child: MaterialApp(
        locale: kTestLocale,
        localizationsDelegates: starLocalizationsDelegates,
        supportedLocales: StarLocalizations.supportedLocales,
        theme: buildStarTheme(
          colorTheme: colorTheme,
          textTheme: StarTextTheme.fromColors(colorTheme),
          layoutTheme: StarLayoutTheme.scaled(),
        ),
        home: Scaffold(body: child),
      ),
    ),
  );
}
