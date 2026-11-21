import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:star_app/core/api/star_client_provider.dart';
import 'package:star_app/core/database/star_database.dart' as db;
import 'package:star_app/core/providers/database_provider.dart';
import 'package:star_app/core/providers/gateway/gateway_connection_provider.dart';
import 'package:star_app/features/members/data/guild_mention_member_search.dart';
import 'package:star_app/features/members/data/member_repository.dart';
import 'package:star_app/features/members/providers/guild_member_chunk_waiter.dart';
import 'package:star_app/features/settings/providers/view_models/user_settings_view_model.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'member_providers.g.dart';

@Riverpod(keepAlive: true)
MemberRepository memberRepository(Ref ref) {
  final client = ref.watch(starClientProvider);
  final database = ref.watch(starDatabaseProvider);
  return MemberRepository(client, database);
}

final Provider<GuildMentionMemberSearch> guildMentionMemberSearchProvider =
    Provider<GuildMentionMemberSearch>((Ref ref) {
      return GuildMentionMemberSearch(
        memberRepository: ref.watch(memberRepositoryProvider),
        chunkWaiter: ref.watch(guildMemberChunkWaiterProvider),
        gateway: ref.watch(gatewayConnectionProvider),
        database: ref.watch(starDatabaseProvider),
      );
    });

@riverpod
Stream<int> guildMemberRowCount(Ref ref, String guildId) {
  if (guildId.isEmpty) {
    return Stream<int>.value(0);
  }
  final database = ref.watch(starDatabaseProvider);
  return database.memberDao.watchMemberCount(guildId);
}

typedef CurrentUserMemberIdentity = ({String? roleIdsJson});

@riverpod
Stream<CurrentUserMemberIdentity?> currentUserMemberIdentity(
  Ref ref,
  String guildId,
) {
  if (guildId.isEmpty) {
    return Stream<CurrentUserMemberIdentity?>.value(null);
  }
  final String userId = ref.watch(
    userSettingsViewModelProvider.select((settings) => settings.userId),
  );
  if (userId.isEmpty) {
    return Stream<CurrentUserMemberIdentity?>.value(null);
  }
  final database = ref.watch(starDatabaseProvider);
  return database.memberDao.watchMemberByUserId(userId, guildId).map((
    db.Member? row,
  ) {
    if (row == null) {
      return null;
    }
    return (roleIdsJson: row.roleIdsJson);
  }).distinct();
}

@riverpod
Stream<String> guildRolePermissionsIdentity(Ref ref, String guildId) {
  if (guildId.isEmpty) {
    return Stream<String>.value('');
  }
  final database = ref.watch(starDatabaseProvider);
  return database.roleDao.watchRoles(guildId).map((List<db.Role> roles) {
    final StringBuffer buffer = StringBuffer();
    for (final db.Role role in roles) {
      buffer
        ..write(role.id)
        ..write(':')
        ..write(role.permissions)
        ..write(';');
    }
    return buffer.toString();
  }).distinct();
}

// Tuple-keyed member row lookup.
// ignore: specify_nonobvious_property_types
final memberRowByGuildProvider = StreamProvider.autoDispose
    .family<db.Member?, (String, String)>(
      (Ref ref, (String, String) key) => ref
          .watch(starDatabaseProvider)
          .memberDao
          .watchMemberByUserId(key.$1, key.$2),
    );
