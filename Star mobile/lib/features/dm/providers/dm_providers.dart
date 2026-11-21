import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:star_app/core/api/star_client_provider.dart';
import 'package:star_app/core/providers/database_provider.dart';
import 'package:star_app/core/providers/instance/instance_runtime_config_provider.dart';
import 'package:star_app/features/channels/providers/read_state_repository_provider.dart';
import 'package:star_app/features/dm/data/dm_repository.dart';
import 'package:star_app/features/guilds/data/guild_user_settings_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'dm_providers.g.dart';

@Riverpod(keepAlive: true)
DmRepository dmRepository(Ref ref) {
  final client = ref.watch(starClientProvider);
  final db = ref.watch(starDatabaseProvider);
  final readStateRepository = ref.watch(readStateRepositoryProvider);
  return DmRepository(
    client,
    db,
    ref.watch(guildUserSettingsRepositoryProvider),
    readStateRepository: readStateRepository,
    productName: ref.watch(
      instanceRuntimeConfigProvider.select((config) => config.productName),
    ),
  );
}
