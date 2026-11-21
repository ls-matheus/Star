import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:star_app/core/database/star_database.dart';
import 'package:star_app/core/permissions/channel_permission_cache_provider.dart';
import 'package:star_app/core/providers/database_provider.dart';
import 'package:star_app/core/router/star_router.dart';
import 'package:star_app/features/chat/providers/slowmode/slowmode_immunity_provider.dart';

import '../../../../helpers/open_test_database.dart';
import 'gated_rebuild_permission_cache.dart';

const String _channelId = 'channel-1';
const String _guildId = 'guild-1';
const String _testAccountUserId = 'test-user-id';

void main() {
  test('an immunity build disposed during its rebuild resolves without a '
      'ref-after-dispose throw', () async {
    final StarDatabase database = openTestDatabase();
    await database.channelDao.upsertChannel(
      ChannelsCompanion.insert(
        id: _channelId,
        guildId: _guildId,
        name: 'general',
      ),
    );

    final Completer<void> gate = Completer<void>();
    final ProviderContainer container = ProviderContainer(
      overrides: [
        starDatabaseProvider.overrideWithValue(database),
        currentUserIdProvider.overrideWithValue(_testAccountUserId),
        channelPermissionCacheProvider(
          _testAccountUserId,
        ).overrideWith(() => GatedRebuildPermissionCache(gate)),
      ],
    );
    addTearDown(container.dispose);

    final Future<bool> immune = container.read(
      isSlowmodeImmuneProvider(_channelId).future,
    );
    await Future<void>.delayed(Duration.zero);

    container.invalidate(isSlowmodeImmuneProvider(_channelId));
    gate.complete();

    await expectLater(immune, completion(isFalse));
  });
}
