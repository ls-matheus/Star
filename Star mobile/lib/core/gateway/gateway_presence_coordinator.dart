import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:star_app/core/gateway/gateway_lifecycle_presence.dart';
import 'package:star_app/core/gateway/presence_update_batcher.dart';
import 'package:star_app/core/platform/star_platform.dart';
import 'package:star_app/core/providers/app/app_ui_lifecycle_provider.dart';
import 'package:star_app/core/providers/gateway/gateway_connection_provider.dart';
import 'package:star_app/core/providers/gateway/gateway_session_recovery_provider.dart';
import 'package:star_app/features/channels/providers/ack_batcher_provider.dart';
import 'package:star_app/features/profile/providers/user_settings_status_provider.dart';
import 'package:star_dart/export.dart';
import 'package:star_dart/gateway.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'gateway_presence_coordinator.g.dart';

const Duration kBackgroundAckFlushTimeout = Duration(seconds: 5);

@Riverpod(keepAlive: true)
void gatewayPresenceCoordinator(Ref ref) {
  bindGatewayPresenceCoordinator(ref, mobileOs: isStarNativeMobileOs);
}

@visibleForTesting
void bindGatewayPresenceCoordinator(Ref ref, {required bool mobileOs}) {
  if (!mobileOs) {
    return;
  }

  GatewayPresence? lastSent;
  int ackFlushesBeforeAfk = 0;

  void sync() {
    if (!ref.read(gatewayHasAuthTokenProvider)) {
      return;
    }
    final UserSettingsResponse? settings = ref.read(userSettingsStatusProvider);
    final GatewayPresence presence = buildGatewayLifecyclePresence(
      isForeground:
          ref.read(appUiForegroundProvider) || ackFlushesBeforeAfk > 0,
      status: settings?.status ?? 'online',
      customStatus: gatewayCustomStatusFromSettings(settings?.customStatus),
      mobile: isStarMobileClient,
      markAfkWhenBackgrounded: true,
    );
    final GatewayPresence? previous = lastSent;
    if (previous != null && sameGatewayPresence(previous, presence)) {
      return;
    }
    lastSent = presence;
    ref.read(gatewayConnectionProvider).updatePresence(presence);
  }

  Future<void> syncAfterAckFlush() async {
    ackFlushesBeforeAfk += 1;
    try {
      await ref
          .read(ackBatcherProvider)
          .flushPending(force: true)
          .timeout(kBackgroundAckFlushTimeout, onTimeout: () {});
    } finally {
      ackFlushesBeforeAfk -= 1;
    }
    if (ref.mounted) {
      sync();
    }
  }

  ref
    ..listen<bool>(appUiForegroundProvider, (bool? previous, bool next) {
      if ((previous ?? false) && !next) {
        unawaited(syncAfterAckFlush());
        return;
      }
      sync();
    })
    ..listen<UserSettingsResponse?>(
      userSettingsStatusProvider,
      (_, _) => sync(),
    )
    ..listen<GatewayConnection>(gatewayConnectionProvider, (_, _) {
      lastSent = null;
      sync();
    })
    ..listen<int>(gatewaySessionRecoveryProvider, (_, _) {
      lastSent = null;
      sync();
    });
  sync();
}
