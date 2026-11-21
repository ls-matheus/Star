import 'dart:async';

import 'package:star_app/core/audio/enums/star_sfx_clip.dart';

typedef MessageNotificationSfxPlayCallback = void Function(StarSfxClip clip);

class MessageNotificationSfxScheduler {
  MessageNotificationSfxScheduler({
    this.debounceMs = 120,
    this.cooldownMs = 900,
    this.maxWaitMs = 1000,
    this.cooldownMsForClip,
  });

  final int debounceMs;
  final int cooldownMs;
  final int maxWaitMs;
  final int? Function(StarSfxClip clip)? cooldownMsForClip;

  Timer? _debounceTimer;
  StarSfxClip? _pendingClip;
  DateTime? _queuedAt;
  DateTime? _lastPlayedAt;

  StarSfxClip? get pendingClip => _pendingClip;

  void dropPending() {
    _debounceTimer?.cancel();
    _debounceTimer = null;
    _pendingClip = null;
    _queuedAt = null;
  }

  void schedule({
    required StarSfxClip clip,
    required MessageNotificationSfxPlayCallback play,
  }) {
    final DateTime now = DateTime.now();
    _pendingClip = clip;
    _queuedAt ??= now;
    _debounceTimer?.cancel();
    final int elapsedMs = now.difference(_queuedAt!).inMilliseconds;
    final int delayMs = elapsedMs >= maxWaitMs
        ? 0
        : _resolveDelayMs(now: now, clip: clip);
    if (delayMs <= 0) {
      _flush(play);
      return;
    }
    _debounceTimer = Timer(Duration(milliseconds: delayMs), () {
      _flush(play);
    });
  }

  int _resolveDelayMs({required DateTime now, required StarSfxClip clip}) {
    final DateTime? lastPlayed = _lastPlayedAt;
    if (lastPlayed == null) {
      return debounceMs;
    }
    final int effectiveCooldown = cooldownMsForClip?.call(clip) ?? cooldownMs;
    final int sinceLastMs = now.difference(lastPlayed).inMilliseconds;
    if (sinceLastMs >= effectiveCooldown) {
      return debounceMs;
    }
    return effectiveCooldown - sinceLastMs;
  }

  void _flush(MessageNotificationSfxPlayCallback play) {
    _debounceTimer?.cancel();
    _debounceTimer = null;
    final StarSfxClip? clip = _pendingClip;
    _pendingClip = null;
    _queuedAt = null;
    if (clip == null) {
      return;
    }
    _lastPlayedAt = DateTime.now();
    play(clip);
  }

  void dispose() {
    dropPending();
    _lastPlayedAt = null;
  }
}
