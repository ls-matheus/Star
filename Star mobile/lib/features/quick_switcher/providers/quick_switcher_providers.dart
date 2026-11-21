import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:star_app/core/providers/database_provider.dart';
import 'package:star_app/features/channels/providers/read_state_write_batcher_provider.dart';
import 'package:star_app/features/quick_switcher/data/quick_switcher_repository.dart';

final Provider<QuickSwitcherRepository> quickSwitcherRepositoryProvider =
    Provider<QuickSwitcherRepository>((Ref ref) {
      return QuickSwitcherRepository(
        ref.watch(starDatabaseProvider),
        ref.watch(readStateWriteBatcherProvider),
      );
    });
