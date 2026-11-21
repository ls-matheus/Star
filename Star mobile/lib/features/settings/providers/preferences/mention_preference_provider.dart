import 'dart:async';

import 'package:star_app/core/api/star_client_provider.dart';
import 'package:star_app/core/database/star_database.dart';
import 'package:star_app/core/providers/database_provider.dart';
import 'package:star_app/core/router/star_router.dart';
import 'package:star_app/features/chat/utils/composer/mention_reply_preference_utils.dart';
import 'package:star_dart/export.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'mention_preference_provider.g.dart';

@riverpod
class MentionReplyPreference extends _$MentionReplyPreference {
  @override
  Stream<MentionReplyPreferences> build() async* {
    final String? userId = ref.watch(currentUserIdProvider);
    if (userId == null) {
      yield MentionReplyPreferences.noPreference;
      return;
    }
    final StarDatabase database = ref.watch(starDatabaseProvider);
    await for (final User? user in database.userDao.watchUserById(userId)) {
      yield mentionFlagsFromDb(user?.mentionFlags) ??
          MentionReplyPreferences.noPreference;
    }
  }

  Future<void> setPreference(MentionReplyPreferences preference) async {
    final String? userId = ref.read(currentUserIdProvider);
    if (userId == null) {
      return;
    }
    final StarDatabase database = ref.read(starDatabaseProvider);
    final dio = ref.read(starDioProvider);
    await dio.patch<dynamic>(
      '/users/@me',
      data: <String, Object?>{'mention_flags': preference.json},
    );
    await database.userDao.updateUserMentionFlags(userId, preference.json);
  }
}
