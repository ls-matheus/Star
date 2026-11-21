import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:star_app/core/database/star_database.dart'
    show StarDatabase;
import 'package:star_app/core/providers/app/account_user_id.dart';
import 'package:star_app/core/providers/database_provider.dart';
import 'package:star_app/core/router/star_router.dart';
import 'package:star_app/core/theme/star_layout_theme.dart';
import 'package:star_app/core/theme/star_text_theme.dart';
import 'package:star_app/core/theme/star_theme.dart';
import 'package:star_app/core/theme/themes/dark.dart';
import 'package:star_app/features/channels/domain/channel.dart';
import 'package:star_app/features/chat/presentation/sheets/channel_details_sheet.dart';
import 'package:star_app/features/dm/domain/dm_conversation.dart';
import 'package:star_app/features/members/domain/member_list_range_utils.dart';
import 'package:star_app/features/members/providers/member_list_desired_ranges_provider.dart';
import 'package:star_app/features/members/providers/member_list_subscription_provider.dart';
import 'package:star_app/features/members/providers/member_list_viewport_provider.dart';
import 'package:star_app/features/settings/providers/preferences/appearance_preferences_provider.dart';
import 'package:star_app/features/ui/list/star_list_row.dart';
import 'package:star_app/material_ui.dart';
import 'package:riverpod/src/framework.dart' show Override;

import '../../../../helpers/open_test_database.dart';
import '../../../../helpers/test_l10n.dart';

const String _guildId = 'guild_1';
const String _channelId = 'chan_1';

class _FakeAppearance extends AppearancePreferences {
  @override
  AppearancePreferencesState build() =>
      const AppearancePreferencesState(showFavorites: false);
}

ProviderContainer _container(StarDatabase database, {String? currentUserId}) {
  final List<Override> overrides = <Override>[
    starDatabaseProvider.overrideWithValue(database),
    appearancePreferencesProvider.overrideWith(_FakeAppearance.new),
    memberListDetailsSubscriptionProvider(
      _guildId,
      _channelId,
      true,
    ).overrideWith((ref) {}),
    if (currentUserId != null)
      currentUserIdProvider.overrideWithValue(currentUserId),
  ];
  return ProviderContainer(overrides: overrides);
}

Widget _host(ProviderContainer container, {required Widget child}) {
  final colorTheme = buildDarkColorTheme();
  return UncontrolledProviderScope(
    container: container,
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
  );
}

void main() {
  testWidgets('DM members tab shows the one-to-one recipient', (tester) async {
    final StarDatabase database = openTestDatabase();
    final ProviderContainer container = _container(
      database,
      currentUserId: '1000000000000000001',
    );
    addTearDown(container.dispose);
    final ScrollController scrollController = ScrollController();
    addTearDown(scrollController.dispose);

    final DmConversation dm = DmConversation(
      id: '1000000000000000002',
      type: 1,
      recipientId: '1000000000000000003',
      recipientName: 'Other User',
      lastMessage: '',
      lastMessageTime: DateTime.fromMillisecondsSinceEpoch(0),
      remoteRecipientIds: const <String>['1000000000000000003'],
    );

    await tester.pumpWidget(
      _host(
        container,
        child: ChannelDetailsSheet(
          channel: null,
          dm: dm,
          initialTab: ChannelDetailsInitialTab.members,
          openSearchImmediately: false,
          scrollController: scrollController,
          close: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.byWidgetPredicate(
        (Widget widget) =>
            widget is StarListRow && widget.title == 'Other User',
      ),
      findsOneWidget,
    );
  });

  testWidgets(
    'disposing a guild-channel sheet clears member-list state without using ref',
    (tester) async {
      final StarDatabase database = openTestDatabase();
      final ProviderContainer container = _container(database);
      addTearDown(container.dispose);
      final ScrollController scrollController = ScrollController();
      addTearDown(scrollController.dispose);

      const Channel channel = Channel(
        id: _channelId,
        guildId: _guildId,
        name: 'general',
      );

      await tester.pumpWidget(
        _host(
          container,
          child: ChannelDetailsSheet(
            channel: channel,
            dm: null,
            initialTab: ChannelDetailsInitialTab.members,
            openSearchImmediately: false,
            scrollController: scrollController,
            close: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      final String key = memberListDesiredRangesKey(_guildId, _channelId);
      container
          .read(
            memberListViewportProvider(readAccountUserId(container)).notifier,
          )
          .setSubscribedRanges(
            guildId: _guildId,
            channelId: _channelId,
            ranges: kMemberListInitialSubscriptionRanges,
          );

      expect(
        container
            .read(memberListDesiredRangesProvider(readAccountUserId(container)))
            .containsKey(key),
        isTrue,
        reason: 'tab content should register desired ranges while mounted',
      );
      expect(
        container
            .read(
              memberListViewportProvider(readAccountUserId(container)).notifier,
            )
            .getList(guildId: _guildId, channelId: _channelId),
        isNotNull,
      );

      await tester.pumpWidget(_host(container, child: const SizedBox.shrink()));
      await tester.pumpAndSettle();

      expect(
        tester.takeException(),
        isNull,
        reason: 'closing the sheet must not throw during dispose',
      );
      expect(
        container
            .read(memberListDesiredRangesProvider(readAccountUserId(container)))
            .containsKey(key),
        isFalse,
        reason: 'dispose should clear the desired ranges for the channel',
      );
      expect(
        container
            .read(
              memberListViewportProvider(readAccountUserId(container)).notifier,
            )
            .getList(guildId: _guildId, channelId: _channelId),
        isNull,
        reason: 'dispose should clear the viewport list for the channel',
      );
    },
  );
}
