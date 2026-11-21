import 'dart:convert';

import 'package:star_app/features/guilds/providers/user_guild_settings_data_provider.dart';
import 'package:star_dart/export.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'channel_mute_provider.g.dart';

@riverpod
AsyncValue<Set<String>> mutedChannelIds(Ref ref, String guildId) {
  return watchUserGuildSettingsData(ref, guildId).whenData(mutedIdsFromData);
}

Set<String> mutedIdsFromData(String? settings) {
  if (settings == null) {
    return const <String>{};
  }

  final data = jsonDecode(settings) as Map<String, dynamic>;
  final gs = UserGuildSettingsResponse.fromJson(data);
  final overrides = gs.channelOverrides;
  if (overrides == null) {
    return const <String>{};
  }

  final muted = <String>{};
  for (final entry in overrides.entries) {
    if (!entry.value.muted) {
      continue;
    }
    final Object? endTimeValue = entry.value.muteConfig?.endTime;
    final String? endTimeStr = endTimeValue is String ? endTimeValue : null;
    if (endTimeStr != null) {
      final endTime = DateTime.tryParse(endTimeStr);
      if (endTime != null && endTime.isBefore(DateTime.now())) {
        continue;
      }
    }
    muted.add(entry.key);
  }
  return muted;
}
