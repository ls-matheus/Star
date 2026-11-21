import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:star_app/core/audio/enums/star_sfx_clip.dart';
import 'package:star_app/core/notifications/system_notification_sound_policy.dart';

const MethodChannel _androidNotificationsChannel = MethodChannel(
  'star_app/android_notifications',
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  tearDown(() {
    debugDefaultTargetPlatformOverride = null;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_androidNotificationsChannel, null);
  });

  test(
    'shouldSuppressRingerRespectingSfx skips non-notification clips',
    () async {
      expect(
        await shouldSuppressRingerRespectingSfx(StarSfxClip.mute),
        isFalse,
      );
    },
  );

  test('shouldSuppressRingerRespectingSfx skips preview playback', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_androidNotificationsChannel, (
          MethodCall call,
        ) async {
          if (call.method == 'isNotificationSoundSuppressed') {
            return true;
          }
          return null;
        });

    expect(
      await shouldSuppressRingerRespectingSfx(
        StarSfxClip.message,
        ignoreRingerPolicy: true,
      ),
      isFalse,
    );
  });

  test(
    'shouldSuppressRingerRespectingSfx follows android ringer policy for messages',
    () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(_androidNotificationsChannel, (
            MethodCall call,
          ) async {
            if (call.method == 'isNotificationSoundSuppressed') {
              return true;
            }
            return null;
          });

      expect(
        await shouldSuppressRingerRespectingSfx(StarSfxClip.message),
        isTrue,
      );
    },
  );
}
