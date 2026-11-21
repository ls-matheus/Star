import 'package:star_app/core/api/star_client_provider.dart';
import 'package:star_app/core/providers/database_provider.dart';
import 'package:star_app/features/channels/data/channel_repository.dart';
import 'package:star_app/features/channels/domain/channel.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'channel_providers.g.dart';

typedef ChannelPermissionIdentity = ({
  String guildId,
  int type,
  String? parentId,
  String? permissionOverwritesJson,
});

@Riverpod(keepAlive: true)
ChannelRepository channelRepository(Ref ref) {
  final client = ref.watch(starClientProvider);
  final dio = ref.watch(starDioProvider);
  final db = ref.watch(starDatabaseProvider);
  return ChannelRepository(client, dio, db);
}

@riverpod
Stream<Channel?> channelById(Ref ref, String id) {
  final db = ref.watch(starDatabaseProvider);
  return db.channelDao
      .watchChannelById(id)
      .map((row) => row == null ? null : Channel.fromRow(row))
      .distinct();
}

@riverpod
Stream<String?> channelGuildId(Ref ref, String id) {
  if (id.isEmpty) {
    return Stream<String?>.value(null);
  }
  final db = ref.watch(starDatabaseProvider);
  return db.channelDao
      .watchChannelById(id)
      .map((row) => row?.guildId)
      .distinct();
}

@riverpod
Stream<ChannelPermissionIdentity?> channelPermissionIdentity(
  Ref ref,
  String id,
) {
  if (id.isEmpty) {
    return Stream<ChannelPermissionIdentity?>.value(null);
  }
  final db = ref.watch(starDatabaseProvider);
  return db.channelDao.watchChannelById(id).map((row) {
    if (row == null) {
      return null;
    }
    return (
      guildId: row.guildId,
      type: row.type,
      parentId: row.parentId,
      permissionOverwritesJson: row.permissionOverwritesJson,
    );
  }).distinct();
}

@riverpod
Stream<List<Channel>> allChannels(Ref ref) {
  final db = ref.watch(starDatabaseProvider);
  return db.channelDao.watchAllChannels().map(
    (rows) => rows.map(Channel.fromRow).toList(),
  );
}
