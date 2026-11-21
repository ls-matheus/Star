import 'dart:async';

import 'package:star_app/core/providers/app/app_ui_lifecycle_provider.dart';
import 'package:star_app/core/push/tray/drain.dart';
import 'package:star_app/core/push/tray/registry_provider.dart';
import 'package:star_app/features/channels/providers/ack_batcher_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'background_listener_provider.g.dart';

@Riverpod(keepAlive: true)
Raw<void> pushTrayBackgroundListener(Ref ref) {
  ref.listen<bool>(appUiForegroundProvider, (bool? previous, bool next) {
    if ((previous ?? false) && !next) {
      unawaited(_onAppBackgrounded(ref));
    }
  });
}

Future<void> _onAppBackgrounded(Ref ref) async {
  await ref.read(ackBatcherProvider).flushPending(force: true);
  await drainPushTrayRegistry(ref.read(pushTrayRegistryProvider));
}
