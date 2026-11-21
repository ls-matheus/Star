import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:star_app/core/database/star_database.dart';
import 'package:star_app/core/providers/database_provider.dart';
import 'package:star_app/features/members/domain/member.dart';

// `FutureProviderFamily` is not exposed by the public API; the explicit type
// would require a `package:riverpod/src/...` import.
// ignore: specify_nonobvious_property_types
final userProfileGuildRolesProvider = FutureProvider.autoDispose
    .family<List<MemberRole>, String>((ref, guildId) async {
      final StarDatabase database = ref.watch(starDatabaseProvider);
      final List<Role> rows = await database.roleDao.getRoles(guildId);
      return rows.map(MemberRole.fromRow).toList(growable: false);
    });

// Same provider-family type issue as above.
// ignore: specify_nonobvious_property_types
final userProfileGuildInfoProvider = FutureProvider.autoDispose
    .family<Server?, String>((ref, guildId) {
      final StarDatabase database = ref.watch(starDatabaseProvider);
      return database.guildDao.getServerById(guildId);
    });

// Same provider-family type issue as above.
// ignore: specify_nonobvious_property_types
final userProfileMutualGuildInfoProvider = FutureProvider.autoDispose
    .family<Map<String, Server>, String>((ref, guildIdsKey) async {
      final StarDatabase database = ref.watch(starDatabaseProvider);
      final Map<String, Server> serversById = <String, Server>{};
      final List<String> guildIds = guildIdsKey
          .split(',')
          .where((String guildId) => guildId.isNotEmpty)
          .toList(growable: false);
      for (final String guildId in guildIds) {
        final Server? server = await database.guildDao.getServerById(guildId);
        if (server != null) {
          serversById[guildId] = server;
        }
      }
      return serversById;
    });
