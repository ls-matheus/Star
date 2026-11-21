import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:star_app/core/audio/enums/star_sfx_clip.dart';
import 'package:star_app/core/audio/message_notification_sfx_scheduler.dart';

void main() {
  group('MessageNotificationSfxScheduler.schedule', () {
    test('dropPending cancels a sound that has not played yet', () {
      fakeAsync((FakeAsync async) {
        final List<StarSfxClip> played = <StarSfxClip>[];
        final MessageNotificationSfxScheduler scheduler =
            MessageNotificationSfxScheduler()
              ..schedule(clip: StarSfxClip.message, play: played.add)
              ..dropPending();
        async.elapse(const Duration(milliseconds: 120));
        expect(played, isEmpty);
        expect(scheduler.pendingClip, isNull);
      });
    });

    test('plays after debounce on first schedule', () {
      fakeAsync((FakeAsync async) {
        final List<StarSfxClip> played = <StarSfxClip>[];
        MessageNotificationSfxScheduler().schedule(
          clip: StarSfxClip.message,
          play: played.add,
        );
        async.flushMicrotasks();
        expect(played, isEmpty);

        async.elapse(const Duration(milliseconds: 120));
        expect(played, <StarSfxClip>[StarSfxClip.message]);
      });
    });

    test('enforces default cooldown between different clips', () {
      fakeAsync((FakeAsync async) {
        final List<StarSfxClip> played = <StarSfxClip>[];
        final MessageNotificationSfxScheduler scheduler =
            MessageNotificationSfxScheduler()
              ..schedule(clip: StarSfxClip.message, play: played.add);
        async.elapse(const Duration(milliseconds: 120));
        expect(played, <StarSfxClip>[StarSfxClip.message]);

        scheduler.schedule(clip: StarSfxClip.directMessage, play: played.add);
        async.flushMicrotasks();
        expect(played, <StarSfxClip>[StarSfxClip.message]);

        async.elapse(const Duration(milliseconds: 900));
        expect(played, <StarSfxClip>[
          StarSfxClip.message,
          StarSfxClip.directMessage,
        ]);
      });
    });

    test('uses longer cooldown for sameChannelMessage when configured', () {
      fakeAsync((FakeAsync async) {
        final List<StarSfxClip> played = <StarSfxClip>[];
        final MessageNotificationSfxScheduler scheduler =
            MessageNotificationSfxScheduler(
              cooldownMsForClip: (StarSfxClip clip) {
                if (clip == StarSfxClip.sameChannelMessage) {
                  return 2000;
                }
                return null;
              },
            )..schedule(
              clip: StarSfxClip.sameChannelMessage,
              play: played.add,
            );
        async.elapse(const Duration(milliseconds: 120));
        expect(played, <StarSfxClip>[StarSfxClip.sameChannelMessage]);

        scheduler.schedule(
          clip: StarSfxClip.sameChannelMessage,
          play: played.add,
        );
        async.elapse(const Duration(milliseconds: 900));
        expect(played, <StarSfxClip>[StarSfxClip.sameChannelMessage]);

        async.elapse(const Duration(milliseconds: 1100));
        expect(played, <StarSfxClip>[
          StarSfxClip.sameChannelMessage,
          StarSfxClip.sameChannelMessage,
        ]);
      });
    });

    test('uses default cooldown for clips without custom cooldown', () {
      fakeAsync((FakeAsync async) {
        final List<StarSfxClip> played = <StarSfxClip>[];
        final MessageNotificationSfxScheduler scheduler =
            MessageNotificationSfxScheduler(
              cooldownMsForClip: (StarSfxClip clip) {
                if (clip == StarSfxClip.sameChannelMessage) {
                  return 2000;
                }
                return null;
              },
            )..schedule(clip: StarSfxClip.message, play: played.add);
        async.elapse(const Duration(milliseconds: 120));
        expect(played, <StarSfxClip>[StarSfxClip.message]);

        scheduler.schedule(clip: StarSfxClip.message, play: played.add);
        async.elapse(const Duration(milliseconds: 900));
        expect(played, <StarSfxClip>[
          StarSfxClip.message,
          StarSfxClip.message,
        ]);
      });
    });

    test('replaces pending clip with the latest scheduled clip', () {
      fakeAsync((FakeAsync async) {
        final List<StarSfxClip> played = <StarSfxClip>[];
        MessageNotificationSfxScheduler()
          ..schedule(clip: StarSfxClip.message, play: played.add)
          ..schedule(clip: StarSfxClip.directMessage, play: played.add);
        async.elapse(const Duration(milliseconds: 120));

        expect(played, <StarSfxClip>[StarSfxClip.directMessage]);
      });
    });
  });

  group('MessageNotificationSfxScheduler.dispose', () {
    test('cancels pending timer without playing', () {
      fakeAsync((FakeAsync async) {
        final List<StarSfxClip> played = <StarSfxClip>[];
        MessageNotificationSfxScheduler()
          ..schedule(clip: StarSfxClip.message, play: played.add)
          ..schedule(clip: StarSfxClip.directMessage, play: played.add)
          ..dispose();
        async
          ..flushMicrotasks()
          ..elapse(const Duration(seconds: 5));

        expect(played, isEmpty);
      });
    });
  });
}
