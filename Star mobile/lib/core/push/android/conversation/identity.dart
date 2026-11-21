import 'package:flutter/foundation.dart';
import 'package:star_app/core/database/star_database.dart';
import 'package:star_app/core/media/star_media_url.dart';
import 'package:star_app/core/push/android/media/instance_urls.dart';
import 'package:star_app/core/push/notification/localization.dart';
import 'package:star_app/core/push/notification/payload.dart';
import 'package:star_app/features/dm/data/dm_conversation_mapper.dart';
import 'package:star_app/features/dm/domain/dm_channel_types.dart';
import 'package:star_app/features/dm/domain/dm_conversation.dart';
import 'package:star_app/features/dm/utils/group_dm_display_name.dart';

final class PushConversationIdentity {
  const PushConversationIdentity({this.name, this.iconUrl});

  static const PushConversationIdentity empty = PushConversationIdentity();

  final String? name;
  final String? iconUrl;
}

final class PushConversationContext {
  const PushConversationContext({
    required this.endpoints,
    required this.identity,
  });

  final PushMediaInstanceUrls endpoints;
  final PushConversationIdentity identity;
}

Future<PushConversationContext> loadPushConversationContext(
  Map<String, String> payload, {
  required String title,
}) async {
  final StarDatabase database = StarDatabase();
  try {
    return PushConversationContext(
      endpoints: await readPushMediaInstanceUrls(
        database,
        payload['target_user_id'],
      ),
      identity: await _loadIdentity(database, payload, title: title),
    );
  } finally {
    await database.close();
  }
}

Future<PushConversationIdentity> _loadIdentity(
  StarDatabase database,
  Map<String, String> payload, {
  required String title,
}) async {
  if (!isPushGroupDmTitle(title) && isDmPushPayload(payload)) {
    return PushConversationIdentity.empty;
  }
  try {
    return await readPushConversationIdentity(database, payload);
  } on Object {
    return PushConversationIdentity.empty;
  }
}

@visibleForTesting
Future<PushConversationIdentity> readPushConversationIdentity(
  StarDatabase database,
  Map<String, String> payload,
) async {
  if (isDmPushPayload(payload)) {
    return await _readGroupDmIdentity(database, payload);
  }
  final String? guildId = payload['guild_id'];
  if (guildId == null) {
    return PushConversationIdentity.empty;
  }
  final Server? guild = await database.guildDao.getServerById(guildId);
  return PushConversationIdentity(
    iconUrl: StarMediaUrl.guildIcon(guildId: guildId, hash: guild?.icon),
  );
}

Future<PushConversationIdentity> _readGroupDmIdentity(
  StarDatabase database,
  Map<String, String> payload,
) async {
  final String? channelId = resolvePushChannelId(payload);
  if (channelId == null) {
    return PushConversationIdentity.empty;
  }
  final DmChannel? row = await database.dmChannelDao.getDmChannelById(
    channelId,
  );
  if (row == null || !isDmGroupType(row.type)) {
    return PushConversationIdentity.empty;
  }
  final DmConversation conversation = await buildDmConversationFromChannelRow(
    database,
    row,
  );
  return PushConversationIdentity(
    name: resolveGroupDmDisplayName(
      dm: conversation,
      l10n: pushNotificationLocalizations(),
      currentUserId: payload['target_user_id'],
    ),
    iconUrl: StarMediaUrl.guildIcon(guildId: channelId, hash: row.icon),
  );
}
