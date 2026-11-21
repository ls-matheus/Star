import 'package:dio/dio.dart';
import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:star_app/core/api/star_client_provider.dart';
import 'package:star_app/core/database/star_database.dart';
import 'package:star_app/core/gateway/gateway_event_handler.dart';
import 'package:star_app/core/providers/database_provider.dart';
import 'package:star_app/features/channels/providers/read_state_write_batcher_provider.dart';
import 'package:star_app/features/dm/data/dm_repository.dart';
import 'package:star_app/features/dm/domain/dm_conversation.dart';
import 'package:star_app/features/dm/providers/dm_providers.dart';
import 'package:star_app/features/dm/providers/dm_view_model.dart';
import 'package:star_app/features/dm/providers/unread_dm_provider.dart';
import 'package:star_app/features/guilds/data/guild_user_settings_repository.dart';
import 'package:star_app/features/quick_switcher/domain/quick_switcher_unread_channel.dart';
import 'package:star_app/features/quick_switcher/providers/quick_switcher_providers.dart';
import 'package:star_app/shared/utils/snowflake_time.dart';
import 'package:star_dart/export.dart';
import 'package:star_dart/gateway.dart';

import '../../../helpers/open_test_database.dart';

String _snowflakeForUtc(DateTime utc) {
  final int internal = (utc.millisecondsSinceEpoch - kSnowflakeEpochMs) << 22;
  return internal.toString();
}

MessageResponseSchema _message({
  required String id,
  required String channelId,
  required String authorId,
}) => MessageResponseSchema(
  id: id,
  channelId: channelId,
  author: UserPartialResponse(
    id: authorId,
    username: 'user-$authorId',
    discriminator: '0001',
    globalName: null,
    avatar: null,
    avatarColor: null,
    flags: 0,
  ),
  type: MessageType.valueDefault,
  flags: 0,
  content: 'hello',
  timestamp: dateTimeFromUserSnowflakeOrNull(id)!,
  pinned: false,
  mentionEveryone: false,
  tts: false,
  mentions: const [],
  mentionRoles: const [],
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'an own DM message leaves the DM read in the rail, list and switcher',
    () async {
      final StarDatabase db = openTestDatabase();
      final String dmId = _snowflakeForUtc(DateTime.utc(2026, 11, 3, 10));
      final String readId = _snowflakeForUtc(DateTime.utc(2026, 11, 3, 11));
      final String ownId = _snowflakeForUtc(DateTime.utc(2026, 11, 3, 12));
      await db.userDao.upsertUser(
        UsersCompanion.insert(id: 'other', username: 'Other'),
      );
      await db.dmChannelDao.upsertDmChannels([
        DmChannelsCompanion.insert(
          id: dmId,
          recipientId: 'other',
          recipientIds: const Value('["other"]'),
          lastMessageId: Value(readId),
          lastMessageTime: Value(dateTimeFromUserSnowflakeOrNull(readId)!),
        ),
      ]);
      await db.messageDao.upsertMessages([
        MessagesCompanion.insert(
          id: readId,
          channelId: dmId,
          authorId: 'other',
          content: 'hi',
          timestamp: dateTimeFromUserSnowflakeOrNull(readId)!,
        ),
      ]);
      await db.readStateDao.upsertReadState(
        ReadStatesCompanion(
          channelId: Value(dmId),
          lastMessageId: Value(readId),
        ),
      );
      final ProviderContainer container = ProviderContainer(
        overrides: [
          starDatabaseProvider.overrideWithValue(db),
          starClientProvider.overrideWithValue(
            StarClient(
              Dio(BaseOptions(baseUrl: 'https://api.star.invalid/v1')),
            ),
          ),
          dmRepositoryProvider.overrideWith(
            (Ref ref) => DmRepository(
              ref.watch(starClientProvider),
              db,
              ref.watch(guildUserSettingsRepositoryProvider),
            ),
          ),
        ],
      );
      addTearDown(container.dispose);
      final rail = container.listen(unreadDmChannelsProvider, (_, _) {});
      addTearDown(rail.close);
      final list = container.listen(dmViewModelProvider, (_, _) {});
      addTearDown(list.close);
      await pumpEventQueue();

      DmConversation listRow() => container
          .read(dmViewModelProvider)
          .conversations
          .singleWhere((DmConversation convo) => convo.id == dmId);
      expect(container.read(unreadDmChannelsProvider).loaded, isTrue);
      expect(container.read(unreadDmChannelsProvider).hasUnread(dmId), isFalse);
      expect(listRow().unreadCount, 0);

      await GatewayEventHandler(
        database: db,
        currentUserId: 'me',
        readStateWriteBatcher: container.read(readStateWriteBatcherProvider),
      ).handle(
        MessageCreateEvent(
          message: _message(id: ownId, channelId: dmId, authorId: 'me'),
        ),
      );
      await pumpEventQueue();

      expect(listRow().lastMessageId, ownId);
      expect(listRow().unreadCount, 0);
      expect(container.read(unreadDmChannelsProvider).hasUnread(dmId), isFalse);
      final List<QuickSwitcherUnreadChannel> switcherUnread = await container
          .read(quickSwitcherRepositoryProvider)
          .getUnreadChannels(
            currentUserId: 'me',
            conversations: container.read(dmViewModelProvider).conversations,
          );
      expect(
        switcherUnread.map((QuickSwitcherUnreadChannel c) => c.channelId),
        isNot(contains(dmId)),
      );
    },
  );
}
