import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:star_app/core/database/star_database.dart';
import 'package:star_app/core/gateway/presence_store.dart';
import 'package:star_app/core/providers/database_provider.dart';

export 'package:star_app/core/gateway/presence_store.dart'
    show PresenceStore, UserPresence;

final Provider<PresenceStore> presenceStoreProvider = Provider<PresenceStore>(
  (Ref ref) => presenceStoreFor(ref.watch(starDatabaseProvider)),
);

final NotifierProviderFamily<UserPresenceNotifier, UserPresence?, String>
userPresenceProvider = NotifierProvider.autoDispose
    .family<UserPresenceNotifier, UserPresence?, String>(
      UserPresenceNotifier.new,
    );

class UserPresenceNotifier extends Notifier<UserPresence?> {
  UserPresenceNotifier(this.userId);

  final String userId;

  @override
  UserPresence? build() {
    final PresenceStore store = ref.watch(presenceStoreProvider);
    ref.onDispose(store.listen(userId, () => state = store[userId]));
    return store[userId];
  }
}

final StreamProviderFamily<User?, String> userRowProvider = StreamProvider
    .autoDispose
    .family<User?, String>(
      (Ref ref, String userId) =>
          ref.watch(starDatabaseProvider).userDao.watchUserById(userId),
    );
