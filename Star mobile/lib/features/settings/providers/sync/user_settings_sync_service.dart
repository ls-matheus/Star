import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:star_app/core/api/star_client_provider.dart';
import 'package:star_app/core/database/star_database.dart';
import 'package:star_app/core/providers/database_provider.dart';
import 'package:star_app/core/router/star_router.dart';
import 'package:star_app/core/talker.dart';
import 'package:star_dart/export.dart';
import 'package:star_dart/models/locale.dart' as sdk;
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'user_settings_sync_service.g.dart';

class UserSettingsSyncService {
  UserSettingsSyncService(Ref ref) : _ref = ref;

  final Ref _ref;

  Future<void> pushTheme(UserThemeType theme) async {
    final client = _ref.read(starClientProvider);
    try {
      await client.users.updateCurrentUserSettings(
        body: UserSettingsUpdateRequest(theme: theme),
      );
      talker.debug('[UserSettingsSync] Pushed theme=${theme.json}');
    } on Object catch (e, st) {
      talker.error('[UserSettingsSync] Push failed', e, st);
      rethrow;
    }
  }

  Future<void> pushTimeFormat(TimeFormatTypes timeFormat) async {
    final client = _ref.read(starClientProvider);
    try {
      await client.users.updateCurrentUserSettings(
        body: UserSettingsUpdateRequest(
          timeFormat: TimeFormatTypesInput.fromJson(timeFormat.json ?? 0),
        ),
      );
      talker.debug('[UserSettingsSync] Pushed timeFormat=${timeFormat.json}');
    } on Object catch (e, st) {
      talker.error('[UserSettingsSync] Push failed', e, st);
      rethrow;
    }
  }

  Future<void> pushAfkTimeout(int minutes) async {
    final client = _ref.read(starClientProvider);
    final String? userId = _ref.read(currentUserIdProvider);
    try {
      final UserSettingsResponse updated = await client.users
          .updateCurrentUserSettings(
            body: UserSettingsUpdateRequest(afkTimeout: minutes * 60),
          );
      await _persistSettings(userId, updated);
      talker.debug('[UserSettingsSync] Pushed afkTimeout=${minutes}m');
    } on Object catch (e, st) {
      talker.error('[UserSettingsSync] Push afkTimeout failed', e, st);
      rethrow;
    }
  }

  Future<void> pushLocale(sdk.Locale locale) async {
    final client = _ref.read(starClientProvider);
    final String? userId = _ref.read(currentUserIdProvider);
    try {
      final UserSettingsResponse updated = await client.users
          .updateCurrentUserSettings(
            body: UserSettingsUpdateRequest(locale: locale),
          );
      await _persistSettings(userId, updated);
      talker.debug('[UserSettingsSync] Pushed locale=${locale.json}');
    } on Object catch (e, st) {
      talker.error('[UserSettingsSync] Push locale failed', e, st);
      rethrow;
    }
  }

  Future<void> _persistSettings(
    String? userId,
    UserSettingsResponse settings,
  ) async {
    if (userId == null || userId != _ref.read(currentUserIdProvider)) {
      return;
    }
    await _ref
        .read(starDatabaseProvider)
        .userSettingsDao
        .upsertSettings(
          UserSettingsTableCompanion(
            userId: Value(userId),
            data: Value(jsonEncode(settings.toJson())),
          ),
        );
  }

  Future<UserSettingsResponse> fetchCurrentSettings() async {
    final client = _ref.read(starClientProvider);
    try {
      return await client.users.getCurrentUserSettings();
    } on Object catch (e, st) {
      talker.error('[UserSettingsSync] Fetch failed', e, st);
      rethrow;
    }
  }
}

@Riverpod(keepAlive: true)
UserSettingsSyncService userSettingsSync(Ref ref) =>
    UserSettingsSyncService(ref);
