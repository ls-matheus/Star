import 'package:flutter_test/flutter_test.dart';
import 'package:star_app/core/audio/enums/star_sfx_clip.dart';

void main() {
  const Set<StarSfxClip> notificationClips = <StarSfxClip>{
    StarSfxClip.message,
    StarSfxClip.directMessage,
    StarSfxClip.sameChannelMessage,
    StarSfxClip.incomingRing,
  };

  const Set<StarSfxClip> sessionFeedbackClips = <StarSfxClip>{
    StarSfxClip.cameraOff,
    StarSfxClip.cameraOn,
    StarSfxClip.deaf,
    StarSfxClip.undeaf,
    StarSfxClip.mute,
    StarSfxClip.unmute,
    StarSfxClip.pttActive,
    StarSfxClip.pttInactive,
    StarSfxClip.streamStart,
    StarSfxClip.streamStop,
    StarSfxClip.userJoin,
    StarSfxClip.userLeave,
    StarSfxClip.userMove,
    StarSfxClip.viewerJoin,
    StarSfxClip.viewerLeave,
    StarSfxClip.voiceDisconnect,
  };

  group('StarSfxClip.respectsRinger', () {
    test('every clip is assigned to exactly one policy', () {
      final Set<StarSfxClip> allClips = StarSfxClip.values.toSet();
      expect(notificationClips.length + sessionFeedbackClips.length, 20);
      expect(notificationClips.union(sessionFeedbackClips), allClips);
      expect(notificationClips.intersection(sessionFeedbackClips), isEmpty);
    });

    test('notification clips respect the ringer', () {
      for (final StarSfxClip clip in notificationClips) {
        expect(clip.respectsRinger, isTrue, reason: clip.name);
      }
    });

    test('session feedback clips ignore the ringer', () {
      for (final StarSfxClip clip in sessionFeedbackClips) {
        expect(clip.respectsRinger, isFalse, reason: clip.name);
      }
    });
  });
}
