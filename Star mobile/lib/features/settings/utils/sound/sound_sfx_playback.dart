import 'dart:async';

import 'package:star_app/core/audio/enums/star_sfx_clip.dart';
import 'package:star_app/core/audio/star_sfx.dart';
import 'package:star_app/core/audio/sound_effect_policy.dart';
import 'package:star_app/core/notifications/system_notification_sound_policy.dart';
import 'package:star_app/features/settings/providers/preferences/sound_preferences_provider.dart';
import 'package:star_app/features/settings/utils/sound/sound_type_utils.dart';
import 'package:star_app/features/settings/utils/sound/sound_volume_utils.dart';

Future<void> playStarSoundEffect({
  required SoundPreferencesState prefs,
  required StarSFX sfx,
  required StarSfxClip clip,
  String? soundType,
  bool ignoreRingerPolicy = false,
  bool notificationsEnabled = true,
}) async {
  final String? resolvedSoundType =
      soundType ?? soundTypeForStarSfxClip(clip);
  if (resolvedSoundType == null) {
    return;
  }
  if (!shouldPlaySoundEffect(
    soundPrefs: prefs,
    soundType: resolvedSoundType,
    notificationsEnabled: notificationsEnabled,
  )) {
    return;
  }
  if (await shouldSuppressRingerRespectingSfx(
    clip,
    ignoreRingerPolicy: ignoreRingerPolicy,
  )) {
    return;
  }
  final double volume = computeEffectiveSfxVolume(
    prefs: prefs,
    soundType: resolvedSoundType,
  );
  await sfx.playOneShot(
    clip,
    volume: volume,
    ignoreRingerPolicy: ignoreRingerPolicy,
  );
}
