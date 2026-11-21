import 'package:star_app/core/api/star_client_provider.dart';
import 'package:star_app/features/settings/data/guild_role_settings_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'guild_role_settings_repository_provider.g.dart';

@riverpod
GuildRoleSettingsRepository guildRoleSettingsRepository(Ref ref) {
  return GuildRoleSettingsRepository(ref.watch(starClientProvider));
}
