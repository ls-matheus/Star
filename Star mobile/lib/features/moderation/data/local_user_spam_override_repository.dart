import 'package:star_app/core/database/daos/local_spam_overrides_dao.dart';
import 'package:star_app/core/database/star_database.dart' as db;
import 'package:star_app/core/synced_preferences/engine/synced_preference_field.dart';
import 'package:star_app/core/synced_preferences/engine/synced_preferences_store.dart';

class LocalUserSpamOverrideRepository {
  LocalUserSpamOverrideRepository(this._database, this._store);

  final db.StarDatabase _database;
  final SyncedPreferencesStore _store;

  Future<LocalSpamOverrideSets> getOverrides() =>
      _database.localSpamOverridesDao.getOverrides();

  Future<void> replaceOverrides(LocalSpamOverrideSets sets) async {
    await _database.localSpamOverridesDao.replaceOverrides(sets);
    _store.markDirty(SyncedPreferenceField.localSpamOverrides);
  }
}
