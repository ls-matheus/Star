import 'dart:async';

import 'package:star_app/core/api/star_client_provider.dart';
import 'package:star_app/core/providers/app/app_ui_lifecycle_provider.dart';
import 'package:star_app/core/providers/database_provider.dart';
import 'package:star_app/core/providers/gateway/gateway_ready_provider.dart';
import 'package:star_app/features/channels/data/ack_batcher.dart';
import 'package:star_app/features/channels/data/read_state_repository.dart';
import 'package:star_dart/export.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'ack_batcher_provider.g.dart';

@Riverpod(keepAlive: true)
AckBatcher ackBatcher(Ref ref) {
  final StarClient client = ref.watch(starClientProvider);
  final db = ref.watch(starDatabaseProvider);
  late final AckBatcher batcher;
  batcher = AckBatcher(
    client: client,
    onResponse: (response) async {
      for (final readState in response.readStates) {
        final String? messageId = readState.lastMessageId;
        if (messageId != null) {
          batcher.cancelIfCovered(readState.id, messageId);
        }
      }
      await ReadStateRepository(client, db).applyAckResponse(response);
    },
  );

  ref
    ..listen<bool>(appUiForegroundProvider, (bool? prev, bool next) {
      batcher.setForegroundBatching(foreground: next);
      if ((prev ?? false) && !next) {
        unawaited(batcher.flushPending(force: true));
      }
    }, fireImmediately: true)
    ..listen<bool>(gatewayReadyProvider, (prev, next) {
      if ((prev ?? false) && !next) {
        unawaited(batcher.flushPending(force: true));
      }
    })
    ..listen<String?>(starAuthTokenProvider, (prev, next) {
      if (prev != next) {
        batcher.clear();
      }
    })
    ..onDispose(() {
      unawaited(batcher.dispose());
    });
  return batcher;
}
