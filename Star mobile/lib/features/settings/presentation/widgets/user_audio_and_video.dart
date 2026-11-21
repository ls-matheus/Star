import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:star_app/core/theme/star_theme_extension.dart';
import 'package:star_app/features/settings/presentation/widgets/voice_mic_test_section.dart';
import 'package:star_app/features/settings/presentation/widgets/wide_settings_content_layout.dart';
import 'package:star_app/features/settings/providers/preferences/voice_prompts_preferences_provider.dart';
import 'package:star_app/features/settings/providers/preferences/voice_settings_provider.dart';
import 'package:star_app/features/ui/ui.dart';
import 'package:star_app/features/voice/domain/voice_output_route.dart';
import 'package:star_app/features/voice/domain/voice_settings_state.dart';
import 'package:star_app/features/voice/presentation/widgets/voice_audio_processing_options.dart';
import 'package:star_app/features/voice/presentation/widgets/voice_change_audio_output_row.dart';
import 'package:star_app/features/voice/providers/voice_media_devices_provider.dart';
import 'package:star_app/features/voice/providers/voice_video_quality_provider.dart';
import 'package:star_app/features/voice/utils/audio/speaker_route.dart';
import 'package:star_app/features/voice/utils/media/camera_platform.dart';
import 'package:star_app/features/voice/utils/media/voice_media_device_label.dart';
import 'package:star_app/features/voice/utils/screen_share/screen_share_presets.dart';
import 'package:star_app/l10n/generated/star_localizations.dart';
import 'package:star_app/material_ui.dart';
import 'package:livekit_client/livekit_client.dart';

class UserAudioAndVideo extends ConsumerStatefulWidget {
  const UserAudioAndVideo({super.key, this.scrollController});

  final ScrollController? scrollController;

  @override
  ConsumerState<UserAudioAndVideo> createState() => _UserAudioAndVideoState();
}

class _UserAudioAndVideoState extends ConsumerState<UserAudioAndVideo> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(ref.read(voiceMediaDevicesProvider.notifier).refresh());
    });
  }

  List<StarSelectItem<String>> _deviceItems(
    StarLocalizations l10n,
    List<VoiceMediaDeviceOption> devices,
  ) {
    return devices
        .map(
          (VoiceMediaDeviceOption device) => StarSelectItem<String>(
            value: device.deviceId,
            label: voiceMediaDeviceLabel(l10n, device),
          ),
        )
        .toList();
  }

  Widget _volumePercentageLabel(double value) {
    return Text('${value.round()}%');
  }

  Widget _volumePercentageMarker(double value) {
    final textStyles = context.textStyles;
    final colors = context.colors;
    final bool isFactoryDefault =
        value == kDefaultVoiceVolumePercent.toDouble();
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Text(
        '${value.round()}%',
        style: textStyles.smallText.copyWith(
          color: isFactoryDefault ? colors.textPositive : colors.textSecondary,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _volumeSlider({
    required double value,
    required ValueChanged<double> onValueChange,
  }) {
    return StarSlider(
      defaultValue: value,
      factoryDefaultValue: kDefaultVoiceVolumePercent.toDouble(),
      minValue: kMinVoiceVolumePercent.toDouble(),
      maxValue: kMaxVoiceVolumePercent.toDouble(),
      markers: const <double>[0, 50, 100, 150, 200],
      step: 1,
      onValueRender: _volumePercentageLabel,
      onMarkerRender: _volumePercentageMarker,
      onValueChange: onValueChange,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = StarLocalizations.of(context);
    final layout = context.layout;
    final VoiceSettingsState settings = ref.watch(voiceSettingsProvider);
    final VoiceSettings settingsNotifier = ref.read(
      voiceSettingsProvider.notifier,
    );
    final VoiceMediaDevicesState devices = ref.watch(voiceMediaDevicesProvider);
    final VoicePromptsPreferencesState prompts = ref.watch(
      voicePromptsPreferencesProvider,
    );
    final VoicePromptsPreferences promptsNotifier = ref.read(
      voicePromptsPreferencesProvider.notifier,
    );
    final VideoQualityCaps videoQualityCaps = ref.watch(
      voiceVideoQualityCapsProvider,
    );
    final bool canSwitchSpeaker = AudioManager.instance.canSwitchSpeakerphone;
    final bool showCameraDevicePicker = !isMobileVoiceCameraPlatform();
    final bool useNativeVoiceAudioRoutePicker =
        showNativeVoiceAudioRoutePicker();
    final bool useAndroidVoiceOutputRoutePicker =
        defaultTargetPlatform == TargetPlatform.android && canSwitchSpeaker;

    return SingleChildScrollView(
      controller: widget.scrollController,
      padding: settingsScrollPadding(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          StarSettingsSection(
            sectionId: 'audio',
            title: l10n.audioAndVideoAudioSectionTitle,
            description: l10n.audioAndVideoAudioSectionDescription,
            isFirst: true,
            children: [
              if (useNativeVoiceAudioRoutePicker ||
                  useAndroidVoiceOutputRoutePicker)
                const VoiceChangeAudioOutputSettingsRow()
              else ...<Widget>[
                StarSelect<String>(
                  label: l10n.audioAndVideoInputDeviceLabel,
                  value: settings.inputDeviceId,
                  items: _deviceItems(l10n, devices.audioInputs),
                  onChanged: (String value) =>
                      unawaited(settingsNotifier.setInputDeviceId(value)),
                ),
                if (canSwitchSpeaker)
                  StarSettingsSwitchItem(
                    label: l10n.audioAndVideoUseSpeakerLabel,
                    description: l10n.audioAndVideoUseSpeakerDescription,
                    value: settings.outputRoute == VoiceOutputRoute.speaker,
                    onChanged: (bool value) => unawaited(
                      settingsNotifier.setOutputRoute(
                        value
                            ? VoiceOutputRoute.speaker
                            : VoiceOutputRoute.earpiece,
                      ),
                    ),
                  )
                else if (devices.audioOutputs.length > 1)
                  StarSelect<String>(
                    label: l10n.audioAndVideoOutputDeviceLabel,
                    value: settings.outputDeviceId,
                    items: _deviceItems(l10n, devices.audioOutputs),
                    onChanged: (String value) =>
                        unawaited(settingsNotifier.setOutputDeviceId(value)),
                  ),
              ],
              StarSettingsSubsection(
                title: l10n.audioAndVideoInputVolumeLabel,
                children: [
                  _volumeSlider(
                    value: settings.inputVolume.toDouble(),
                    onValueChange: (double value) => unawaited(
                      settingsNotifier.setInputVolume(value.round()),
                    ),
                  ),
                ],
              ),
              StarSettingsSubsection(
                title: l10n.audioAndVideoOutputVolumeLabel,
                children: [
                  _volumeSlider(
                    value: settings.outputVolume.toDouble(),
                    onValueChange: (double value) => unawaited(
                      settingsNotifier.setOutputVolume(value.round()),
                    ),
                  ),
                ],
              ),
              StarSettingsSubsection(
                title: l10n.audioAndVideoVoiceProcessingSectionTitle,
                children: const <Widget>[VoiceAudioProcessingOptions()],
              ),
              StarSettingsSubsection(
                title: l10n.audioAndVideoMicTestSectionTitle,
                children: const [VoiceMicTestSection()],
              ),
            ],
          ),
          StarSettingsSection(
            sectionId: 'video',
            title: l10n.audioAndVideoVideoSectionTitle,
            description: l10n.audioAndVideoVideoSectionDescription,
            children: [
              if (showCameraDevicePicker) ...[
                StarSelect<String>(
                  label: l10n.audioAndVideoCameraLabel,
                  value: settings.videoDeviceId,
                  items: _deviceItems(l10n, devices.videoInputs),
                  onChanged: (String value) =>
                      unawaited(settingsNotifier.setVideoDeviceId(value)),
                ),
                SizedBox(height: layout.s4),
              ],
              StarSettingsSwitchItem(
                label: l10n.audioAndVideoMirrorCameraLabel,
                value: settings.mirrorCamera,
                onChanged: (bool value) =>
                    unawaited(settingsNotifier.setMirrorCamera(value: value)),
              ),
              StarSettingsSubsection(
                title: l10n.audioAndVideoCameraQualitySectionTitle,
                children: [
                  StarRadioGroup<CameraResolution>(
                    value: settings.cameraResolution,
                    onChanged: (CameraResolution value) {
                      if (!videoQualityCaps.allowsCameraResolution(value)) {
                        return;
                      }
                      unawaited(settingsNotifier.setCameraResolution(value));
                    },
                    items: [
                      StarRadioItem(
                        value: CameraResolution.low,
                        label: l10n.audioAndVideoCameraQuality480pLabel,
                      ),
                      StarRadioItem(
                        value: CameraResolution.medium,
                        label: l10n.audioAndVideoCameraQuality720pLabel,
                      ),
                      StarRadioItem(
                        value: CameraResolution.high,
                        label: l10n.audioAndVideoCameraQuality1080pLabel,
                      ),
                    ],
                  ),
                ],
              ),
              StarSettingsSubsection(
                title: l10n.audioAndVideoScreenShareQualitySectionTitle,
                children: [
                  StarRadioGroup<ScreenshareResolution>(
                    value: settings.screenshareResolution,
                    onChanged: (ScreenshareResolution value) {
                      if (!videoQualityCaps.allowsScreenShareResolution(
                        value,
                      )) {
                        return;
                      }
                      unawaited(
                        settingsNotifier.setScreenshareResolution(value),
                      );
                    },
                    items: [
                      StarRadioItem(
                        value: ScreenshareResolution.low480p,
                        label: l10n.audioAndVideoCameraQuality480pLabel,
                      ),
                      StarRadioItem(
                        value: ScreenshareResolution.medium,
                        label: l10n.audioAndVideoCameraQuality720pLabel,
                      ),
                      StarRadioItem(
                        value: ScreenshareResolution.high,
                        label: l10n.audioAndVideoCameraQuality1080pLabel,
                      ),
                    ],
                  ),
                ],
              ),
              StarSettingsSubsection(
                title: l10n.audioAndVideoFrameRateSectionTitle,
                children: [
                  StarRadioGroup<int>(
                    value: settings.videoFrameRate,
                    onChanged: (int value) {
                      if (!videoQualityCaps.allowsFrameRate(value)) {
                        return;
                      }
                      unawaited(settingsNotifier.setVideoFrameRate(value));
                    },
                    items: [
                      StarRadioItem(
                        value: 15,
                        label: l10n.audioAndVideoFrameRate15Label,
                      ),
                      StarRadioItem(
                        value: 30,
                        label: l10n.audioAndVideoFrameRate30Label,
                      ),
                      StarRadioItem(
                        value: 60,
                        label: l10n.audioAndVideoFrameRate60Label,
                      ),
                    ],
                  ),
                ],
              ),
              if (!videoQualityCaps.allowsScreenShareResolution(
                    ScreenshareResolution.high,
                  ) &&
                  !videoQualityCaps.allowsFrameRate(60))
                Padding(
                  padding: EdgeInsets.only(top: layout.s3),
                  child: Text(
                    l10n.audioAndVideoInstanceVideoQualityLimit,
                    style: context.textStyles.bodySmall.copyWith(fontSize: 13),
                  ),
                ),
            ],
          ),
          StarSettingsSection(
            title: l10n.audioAndVideoInCallBehaviorSectionTitle,
            description: l10n.audioAndVideoInCallBehaviorSectionDescription,
            children: [
              StarSettingsSwitchGroup(
                children: [
                  StarSettingsSwitchItem.grouped(
                    label: l10n.audioAndVideoSkipHideOwnCameraConfirmLabel,
                    value: prompts.skipHideOwnCameraConfirm,
                    onChanged: (bool value) => unawaited(
                      promptsNotifier.setSkipHideOwnCameraConfirm(value: value),
                    ),
                  ),
                  StarSettingsSwitchItem.grouped(
                    label: l10n.audioAndVideoSkipHideOwnScreenshareConfirmLabel,
                    value: prompts.skipHideOwnScreenshareConfirm,
                    onChanged: (bool value) => unawaited(
                      promptsNotifier.setSkipHideOwnScreenshareConfirm(
                        value: value,
                      ),
                    ),
                  ),
                  StarSettingsSwitchItem.grouped(
                    label: l10n.voiceP2pAlwaysAgreeSettingLabel,
                    description: l10n.voiceP2pAlwaysAgreeSettingDescription,
                    value: prompts.skipP2pJoinConfirm,
                    onChanged: (bool value) => unawaited(
                      promptsNotifier.setSkipP2pJoinConfirm(value: value),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
