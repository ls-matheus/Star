import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:star_app/core/audio/enums/star_sfx_clip.dart';

const MethodChannel _androidNotificationsChannel = MethodChannel(
  'star_app/android_notifications',
);

Future<bool> isSystemNotificationSoundSuppressed() async {
  if (defaultTargetPlatform != TargetPlatform.android) {
    return false;
  }
  try {
    final bool? suppressed = await _androidNotificationsChannel
        .invokeMethod<bool>('isNotificationSoundSuppressed');
    return suppressed ?? false;
  } on PlatformException {
    return false;
  } on MissingPluginException {
    return false;
  }
}

Future<bool> shouldSuppressRingerRespectingSfx(
  StarSfxClip clip, {
  bool ignoreRingerPolicy = false,
}) async {
  if (ignoreRingerPolicy || !clip.respectsRinger) {
    return false;
  }
  return await isSystemNotificationSoundSuppressed();
}
