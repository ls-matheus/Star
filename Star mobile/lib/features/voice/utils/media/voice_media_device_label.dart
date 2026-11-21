import 'package:star_app/features/voice/domain/voice_settings_state.dart';
import 'package:star_app/features/voice/providers/voice_media_devices_provider.dart';
import 'package:star_app/l10n/generated/star_localizations.dart';

String voiceMediaDeviceLabel(
  StarLocalizations l10n,
  VoiceMediaDeviceOption device,
) {
  if (device.deviceId == kDefaultVoiceDeviceId) {
    return l10n.audioAndVideoDefaultDeviceLabel;
  }
  if (device.label.isNotEmpty) {
    return device.label;
  }
  return device.deviceId;
}
