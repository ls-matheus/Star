import 'dart:async';

import 'package:drift/drift.dart' show CancellationException;
import 'package:star_app/core/audio/enums/star_sfx_clip.dart';
import 'package:star_app/core/audio/star_sfx.dart';
import 'package:star_app/core/audio/message_notification_sfx_scheduler.dart';
import 'package:star_app/core/audio/sound_effect_policy.dart';
import 'package:star_app/core/desktop/window/desktop_main_window.dart';
import 'package:star_app/core/platform/star_platform.dart';
import 'package:star_app/core/providers/app/app_ui_lifecycle_provider.dart';
import 'package:star_app/core/providers/app/obscuring_overlay_tracker_provider.dart';
import 'package:star_app/core/router/star_router.dart';
import 'package:star_app/core/router/route_state_providers.dart';
import 'package:star_app/features/chat/providers/messages/message_realtime_events.dart';
import 'package:star_app/features/chat/providers/messages/message_realtime_provider.dart';
import 'package:star_app/features/chat/services/message_notification_sfx_gate.dart';
import 'package:star_app/features/friends/providers/blocked_user_ids_provider.dart';
import 'package:star_app/features/profile/domain/presence_notification_policy.dart';
import 'package:star_app/features/profile/providers/user_settings_status_provider.dart';
import 'package:star_app/features/settings/providers/preferences/notification_preferences_provider.dart';
import 'package:star_app/features/settings/providers/preferences/sound_preferences_provider.dart';
import 'package:star_app/features/settings/utils/sound/sound_sfx_playback.dart';
import 'package:star_app/features/settings/utils/sound/sound_type_utils.dart';
import 'package:star_app/features/settings/utils/sound/sound_volume_utils.dart';
import 'package:star_app/features/voice/providers/pending_incoming_voice_calls_provider.dart';
import 'package:star_app/features/voice/utils/callkit/callkit_policy.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'star_sfx_provider.g.dart';

bool _soundEffectAllowed(Ref ref, String soundType) {
  return shouldPlaySoundEffect(
    notificationsEnabled: ref
        .read(notificationPreferencesProvider)
        .notificationsEnabled,
    soundPrefs: ref.read(soundPreferencesProvider),
    soundType: soundType,
  );
}

void _playConfiguredSfx(Ref ref, StarSfxClip clip) {
  unawaited(
    playStarSoundEffect(
      prefs: ref.read(soundPreferencesProvider),
      sfx: ref.read(starSfxProvider),
      clip: clip,
      notificationsEnabled: ref
          .read(notificationPreferencesProvider)
          .notificationsEnabled,
    ),
  );
}

void _dropDisallowedPendingSfx(
  Ref ref,
  MessageNotificationSfxScheduler scheduler,
) {
  final StarSfxClip? pending = scheduler.pendingClip;
  if (pending == null) {
    return;
  }
  final String? soundType = soundTypeForStarSfxClip(pending);
  if (soundType == null || !_soundEffectAllowed(ref, soundType)) {
    scheduler.dropPending();
  }
}

bool _messageSfxForeground(Ref ref) =>
    isStarDesktopOs || ref.read(appUiForegroundProvider);

StarSfxClip _clipForKind(MessageNotificationSfxClipKind kind) {
  return switch (kind) {
    MessageNotificationSfxClipKind.message => StarSfxClip.message,
    MessageNotificationSfxClipKind.directMessage => StarSfxClip.directMessage,
    MessageNotificationSfxClipKind.sameChannelMessage =>
      StarSfxClip.sameChannelMessage,
  };
}

void _scheduleMessageNotificationSfx({
  required Ref ref,
  required MessageNotificationSfxScheduler scheduler,
  required MessageNotificationSfxPlayRequest request,
}) {
  if (!_soundEffectAllowed(ref, request.clipKind.soundSettingsKey)) {
    return;
  }
  final StarSfxClip clip = _clipForKind(request.clipKind);
  scheduler.schedule(
    clip: clip,
    play: (StarSfxClip scheduledClip) {
      if (!_messageSfxForeground(ref)) {
        return;
      }
      _playConfiguredSfx(ref, scheduledClip);
    },
  );
}

Future<void> _playBestEffortMessageSfxAfterCancellation({
  required Ref ref,
  required MessageCreated evt,
  required MessageNotificationSfxDeduper deduper,
  required MessageNotificationSfxScheduler scheduler,
}) async {
  final String? uid = ref.read(currentUserIdProvider);
  if (uid == null || !_messageSfxForeground(ref)) {
    return;
  }
  try {
    final MessageNotificationSfxPlayRequest? request =
        await StarMessageNotificationSfxEvaluator.evaluateFromSnapshot(
          message: evt.event.message,
          snapshot: evt.snapshot,
          currentUserId: uid,
          blockedUserIds: const <String>{},
          selfIsDnd: false,
          deduper: deduper,
          foreground: true,
          viewingChannel: false,
          hasObscuringOverlay: false,
        );
    if (request == null) {
      return;
    }
    _scheduleMessageNotificationSfx(
      ref: ref,
      scheduler: scheduler,
      request: request,
    );
  } on CancellationException {
    // Ignore any errors
  }
}

@Riverpod(keepAlive: true)
StarSFX starSfx(Ref ref) {
  final StarSFX sfx = StarSFX();
  ref.onDispose(() {
    unawaited(sfx.dispose());
  });
  return sfx;
}

@Riverpod(keepAlive: true)
void starMessageSfxBinding(Ref ref) {
  final MessageNotificationSfxDeduper deduper = MessageNotificationSfxDeduper(
    capacity: 500,
  );
  final MessageNotificationSfxScheduler scheduler =
      MessageNotificationSfxScheduler(
        cooldownMsForClip: (StarSfxClip clip) {
          if (clip == StarSfxClip.sameChannelMessage) {
            return 2000;
          }
          return null;
        },
      );
  ref.onDispose(scheduler.dispose);
  void refreshQueuedSfx() {
    _dropDisallowedPendingSfx(ref, scheduler);
  }

  ref
    ..listen(soundPreferencesProvider, (_, _) => refreshQueuedSfx())
    ..listen(notificationPreferencesProvider, (_, _) => refreshQueuedSfx())
    ..listen<bool>(appUiForegroundProvider, (_, bool foreground) {
      if (!foreground && !isStarDesktopOs) {
        scheduler.dropPending();
      }
    });
  final StreamSubscription<MessageRealtimeEvent> sub = ref
      .read(messageRealtimeBusProvider)
      .stream
      .listen((MessageRealtimeEvent evt) async {
        if (evt is! MessageCreated) {
          return;
        }
        try {
          final String? uid = ref.read(currentUserIdProvider);
          if (uid == null) {
            return;
          }
          final bool selfDnd = isPresenceDoNotDisturb(
            ref.read(userSettingsStatusProvider)?.status,
          );
          final bool foreground = _messageSfxForeground(ref);
          final String? activeCh = ref.read(activeChannelIdProvider);
          final MessageNotificationSfxPlayRequest? request =
              await StarMessageNotificationSfxEvaluator.evaluateFromSnapshot(
                message: evt.event.message,
                snapshot: evt.snapshot,
                currentUserId: uid,
                blockedUserIds: ref.read(blockedUserIdsProvider),
                selfIsDnd: selfDnd,
                deduper: deduper,
                foreground: foreground,
                viewingChannel:
                    activeCh != null &&
                    activeCh == evt.event.message.channelId &&
                    (!isStarDesktopOs || isDesktopMainWindowFocused()),
                hasObscuringOverlay: ref.read(hasObscuringOverlayProvider),
              );
          if (request == null) {
            return;
          }
          _scheduleMessageNotificationSfx(
            ref: ref,
            scheduler: scheduler,
            request: request,
          );
        } on CancellationException {
          await _playBestEffortMessageSfxAfterCancellation(
            ref: ref,
            evt: evt,
            deduper: deduper,
            scheduler: scheduler,
          );
        }
      });
  ref.onDispose(sub.cancel);
}

@Riverpod(keepAlive: true)
void starSfxIncomingRingBinding(Ref ref) {
  final StarSFX sfx = ref.read(starSfxProvider);
  bool isIncomingRingPlaying = false;
  final bool isNativeVoiceCallKitPlatform = isStarNativeMobileOs;
  void syncIncomingRingLoop() {
    final List<String> pending = ref.read(
      pendingIncomingVoiceChannelIdsProvider,
    );
    final bool isForeground = ref.read(appUiForegroundProvider);
    final bool shouldPlay = shouldPlayIncomingVoiceRingSfx(
      isNativeVoiceCallKitPlatform: isNativeVoiceCallKitPlatform,
      isForeground: isForeground,
      hasPendingIncoming: pending.isNotEmpty,
    );
    final SoundPreferencesState soundPrefs = ref.read(soundPreferencesProvider);
    final bool soundEnabled = shouldPlaySoundEffect(
      soundPrefs: soundPrefs,
      soundType: kSoundTypeIncomingRing,
    );
    if (shouldPlay && soundEnabled) {
      final double volume = computeEffectiveSfxVolume(
        prefs: soundPrefs,
        soundType: kSoundTypeIncomingRing,
      );
      unawaited(() async {
        final bool started = await sfx.startLoop(
          StarSfxClip.incomingRing,
          volume: volume,
        );
        if (started) {
          isIncomingRingPlaying = true;
        }
      }());
      return;
    }
    if (!isIncomingRingPlaying) {
      return;
    }
    isIncomingRingPlaying = false;
    unawaited(sfx.stopLoop());
  }

  ref
    ..listen<List<String>>(pendingIncomingVoiceChannelIdsProvider, (_, _) {
      syncIncomingRingLoop();
    }, fireImmediately: true)
    ..listen<bool>(appUiForegroundProvider, (_, _) {
      syncIncomingRingLoop();
    })
    ..listen(soundPreferencesProvider, (_, _) {
      syncIncomingRingLoop();
    });
}
