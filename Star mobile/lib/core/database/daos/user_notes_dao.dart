import 'package:drift/drift.dart';
import 'package:star_app/core/database/drift_stream_utils.dart';
import 'package:star_app/core/database/star_database.dart';
import 'package:star_app/core/database/tables/user_notes.dart';

part 'user_notes_dao.g.dart';

@DriftAccessor(tables: [UserNotesTable])
class UserNotesDao extends DatabaseAccessor<StarDatabase>
    with _$UserNotesDaoMixin {
  UserNotesDao(super.attachedDatabase);

  Future<UserNotesTableData?> getNote(String targetUserId) => (select(
    userNotesTable,
  )..where((t) => t.targetUserId.equals(targetUserId))).getSingleOrNull();

  Stream<UserNotesTableData?> watchNote(String targetUserId) =>
      (select(userNotesTable)
            ..where((t) => t.targetUserId.equals(targetUserId)))
          .watchSingleOrNull()
          .suppressDriftCancellation;

  Future<void> upsertNote(UserNotesTableCompanion entry) =>
      into(userNotesTable).insertOnConflictUpdate(entry);

  Future<void> deleteNote(String targetUserId) => (delete(
    userNotesTable,
  )..where((t) => t.targetUserId.equals(targetUserId))).go();

  Future<void> replaceAll(List<UserNotesTableCompanion> entries) async {
    await transaction(() async {
      await delete(userNotesTable).go();
      await batch((b) {
        for (final entry in entries) {
          b.insert(userNotesTable, entry);
        }
      });
    });
  }

  Future<void> clearAll() => delete(userNotesTable).go();
}
