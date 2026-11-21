import 'package:star_app/core/api/star_client_provider.dart';
import 'package:star_app/core/providers/database_provider.dart';
import 'package:star_app/core/push/tray/registry_provider.dart';
import 'package:star_app/features/channels/data/read_state_repository.dart';
import 'package:star_app/features/channels/providers/ack_batcher_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'read_state_repository_provider.g.dart';

@Riverpod(keepAlive: true)
ReadStateRepository readStateRepository(Ref ref) {
  return ReadStateRepository(
    ref.watch(starClientProvider),
    ref.watch(starDatabaseProvider),
    batcher: ref.watch(ackBatcherProvider),
    trayRegistry: ref.watch(pushTrayRegistryProvider),
  );
}
