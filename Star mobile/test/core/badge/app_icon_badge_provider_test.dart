import 'package:drift/drift.dart' show Value;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:star_app/core/badge/app_icon_badge.dart';
import 'package:star_app/core/badge/app_icon_badge_provider.dart';
import 'package:star_app/core/database/star_database.dart';
import 'package:star_app/core/providers/database_provider.dart';
import 'package:star_app/core/providers/gateway/gateway_ready_provider.dart';
import 'package:star_app/core/router/star_router.dart';
import 'package:star_app/features/guilds/providers/guild_read_state_ready_provider.dart';

import '../../helpers/open_test_database.dart';
import '../../helpers/test_account_user_id.dart';

Future<ProviderContainer> _containerWithDmMention() async {
  final db = openTestDatabase();
  await db.dmChannelDao.upsertDmChannels([
    DmChannelsCompanion.insert(
      id: 'dm-1',
      recipientId: 'other',
      unreadCount: const Value(0),
    ),
  ]);
  await db.readStateDao.upsertReadState(
    const ReadStatesCompanion(channelId: Value('dm-1'), mentionCount: Value(1)),
  );
  final container = ProviderContainer(
    overrides: [
      starDatabaseProvider.overrideWithValue(db),
      currentUserIdProvider.overrideWithValue(kTestAccountUserId),
    ],
  );
  addTearDown(container.dispose);
  return container;
}

void main() {
  test(
    'stays unknown until the gateway and guild unread seed are ready',
    () async {
      final container = await _containerWithDmMention();
      final subscription = container.listen(appIconBadgeProvider, (_, _) {});
      addTearDown(subscription.close);

      await pumpEventQueue();
      expect(container.read(appIconBadgeProvider), isNull);

      container.read(gatewayReadyProvider.notifier).setReady();
      container.read(guildReadStateReadyProvider.notifier).markReady();
      await pumpEventQueue();

      expect(container.read(appIconBadgeProvider)?.count, 1);
    },
  );

  test('keeps the last count while the gateway reconnects', () async {
    final container = await _containerWithDmMention();
    final subscription = container.listen(appIconBadgeProvider, (_, _) {});
    addTearDown(subscription.close);
    container.read(gatewayReadyProvider.notifier).setReady();
    container.read(guildReadStateReadyProvider.notifier).markReady();
    await pumpEventQueue();
    expect(container.read(appIconBadgeProvider)?.count, 1);

    container.read(gatewayReadyProvider.notifier).reset();
    await pumpEventQueue();

    expect(container.read(gatewayReadyProvider), isFalse);
    expect(container.read(appIconBadgeProvider)?.count, 1);
  });

  test(
    'badge does not re-emit on an unrelated (non-DM) read-state change',
    () async {
      final container = await _containerWithDmMention();
      final db = container.read(starDatabaseProvider);
      container.read(gatewayReadyProvider.notifier).setReady();
      container.read(guildReadStateReadyProvider.notifier).markReady();

      var emissions = 0;
      final subscription = container.listen(
        appIconBadgeProvider,
        (_, _) => emissions++,
      );
      addTearDown(subscription.close);

      await pumpEventQueue();
      final settledEmissions = emissions;
      expect(container.read(appIconBadgeProvider)?.count, 1);

      await db.readStateDao.upsertReadState(
        const ReadStatesCompanion(
          channelId: Value('guild-chan-1'),
          mentionCount: Value(5),
        ),
      );
      await pumpEventQueue();

      expect(emissions, settledEmissions);
      expect(container.read(appIconBadgeProvider), isA<AppIconBadgeValue>());
    },
  );
}
