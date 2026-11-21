import 'package:star_app/core/api/star_client_provider.dart';
import 'package:star_app/features/settings/data/guild_settings_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'guild_settings_repository_provider.g.dart';

@Riverpod(keepAlive: true)
GuildSettingsRepository guildSettingsRepository(Ref ref) {
  return GuildSettingsRepository(ref.watch(starClientProvider));
}
