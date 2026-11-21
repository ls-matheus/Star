import 'package:star_app/core/api/star_client_provider.dart';
import 'package:star_app/core/providers/database_provider.dart';
import 'package:star_app/features/guilds/data/guild_repository.dart';
import 'package:star_app/features/guilds/domain/guild.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'guild_providers.g.dart';

@Riverpod(keepAlive: true)
GuildRepository guildRepository(Ref ref) {
  final client = ref.watch(starClientProvider);
  final db = ref.watch(starDatabaseProvider);
  return GuildRepository(client, db);
}

@riverpod
Future<Guild?> guildById(Ref ref, String id) async {
  final db = ref.watch(starDatabaseProvider);
  final row = await db.guildDao.getServerById(id);
  return row == null ? null : Guild.fromRow(row);
}

@riverpod
Stream<Guild?> guildStreamById(Ref ref, String id) {
  final db = ref.watch(starDatabaseProvider);
  return db.guildDao
      .watchServerById(id)
      .map((row) => row == null ? null : Guild.fromRow(row));
}
