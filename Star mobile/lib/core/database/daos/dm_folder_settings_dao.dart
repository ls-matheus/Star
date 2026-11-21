import 'package:drift/drift.dart';

import 'package:star_app/core/database/star_database.dart';
import 'package:star_app/core/database/tables/dm_folder_settings.dart';

part 'dm_folder_settings_dao.g.dart';

@DriftAccessor(tables: [DmFolderSettingsTable])
class DmFolderSettingsDao extends DatabaseAccessor<StarDatabase>
    with _$DmFolderSettingsDaoMixin {
  DmFolderSettingsDao(super.attachedDatabase);

  Future<DmFolderSettingsTableData?> getSettings() => (select(
    dmFolderSettingsTable,
  )..where((t) => t.id.equals(0))).getSingleOrNull();

  Future<void> upsertSettings(DmFolderSettingsTableCompanion companion) =>
      into(dmFolderSettingsTable).insertOnConflictUpdate(companion);

  Future<void> clearAll() => delete(dmFolderSettingsTable).go();
}
