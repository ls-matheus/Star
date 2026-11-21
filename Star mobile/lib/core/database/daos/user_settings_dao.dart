import 'package:drift/drift.dart';
import 'package:star_app/core/database/drift_stream_utils.dart';
import 'package:star_app/core/database/star_database.dart';
import 'package:star_app/core/database/tables/user_settings.dart';

part 'user_settings_dao.g.dart';

@DriftAccessor(tables: [UserSettingsTable])
class UserSettingsDao extends DatabaseAccessor<StarDatabase>
    with _$UserSettingsDaoMixin {
  UserSettingsDao(super.attachedDatabase);

  Future<UserSettingsTableData?> getSettings(String userId) => (select(
    userSettingsTable,
  )..where((t) => t.userId.equals(userId))).getSingleOrNull();

  Stream<UserSettingsTableData?> watchSettings(String userId) =>
      (select(userSettingsTable)..where((t) => t.userId.equals(userId)))
          .watchSingleOrNull()
          .suppressDriftCancellation;

  Future<void> upsertSettings(UserSettingsTableCompanion entry) =>
      into(userSettingsTable).insertOnConflictUpdate(entry);

  Future<void> clearAll() => delete(userSettingsTable).go();
}
