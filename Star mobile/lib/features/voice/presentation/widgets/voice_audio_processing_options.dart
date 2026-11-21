import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:star_app/features/settings/providers/preferences/voice_settings_provider.dart';
import 'package:star_app/features/ui/ui.dart';
import 'package:star_app/features/voice/domain/voice_settings_state.dart';
import 'package:star_app/features/voice/providers/voice_noise_filter_provider.dart';
import 'package:star_app/l10n/generated/star_localizations.dart';
import 'package:star_app/material_ui.dart';

class VoiceAudioProcessingOptions extends ConsumerWidget {
  const VoiceAudioProcessingOptions({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final StarLocalizations l10n = StarLocalizations.of(context);
    final VoiceSettingsState settings = ref.watch(voiceSettingsProvider);
    final VoiceSettings settingsNotifier = ref.read(
      voiceSettingsProvider.notifier,
    );
    final bool noiseFilterSupported = ref
        .watch(voiceNoiseFilterProvider)
        .maybeWhen(
          data: (VoiceNoiseFilterState value) => value.isSupported,
          orElse: () => false,
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        StarRadioGroup<VoiceProcessingMode>(
          value: settings.voiceProcessingMode,
          onChanged: (VoiceProcessingMode value) {
            unawaited(settingsNotifier.setVoiceProcessingMode(value));
          },
          items: <StarRadioItem<VoiceProcessingMode>>[
            StarRadioItem(
              value: VoiceProcessingMode.voice,
              label: l10n.audioAndVideoFocusedVoiceLabel,
              description: l10n.audioAndVideoFocusedVoiceDescription,
            ),
            StarRadioItem(
              value: VoiceProcessingMode.studio,
              label: l10n.audioAndVideoDirectInputLabel,
              description: l10n.audioAndVideoDirectInputDescription,
            ),
            StarRadioItem(
              value: VoiceProcessingMode.custom,
              label: l10n.audioAndVideoCustomProfileLabel,
              description: l10n.audioAndVideoCustomProfileDescription,
            ),
          ],
        ),
        if (settings.voiceProcessingMode == VoiceProcessingMode.custom)
          StarSettingsSubsection(
            title: l10n.audioAndVideoNoiseSuppressionSectionTitle,
            children: <Widget>[
              StarRadioGroup<NoiseSuppressionTier>(
                value: settings.noiseSuppressionTier,
                onChanged: (NoiseSuppressionTier value) {
                  unawaited(settingsNotifier.setNoiseSuppressionTier(value));
                },
                items: <StarRadioItem<NoiseSuppressionTier>>[
                  StarRadioItem(
                    value: NoiseSuppressionTier.enhanced,
                    label: l10n.audioAndVideoNoiseSuppressionEnhancedLabel,
                    enabled: noiseFilterSupported,
                  ),
                  StarRadioItem(
                    value: NoiseSuppressionTier.standard,
                    label: l10n.audioAndVideoNoiseSuppressionStandardLabel,
                  ),
                  StarRadioItem(
                    value: NoiseSuppressionTier.none,
                    label: l10n.audioAndVideoNoiseSuppressionNoneLabel,
                  ),
                ],
              ),
              StarSettingsSwitchItem(
                label: l10n.audioAndVideoEchoCancellationLabel,
                value: settings.echoCancellation,
                onChanged: (bool value) {
                  unawaited(settingsNotifier.setEchoCancellation(value: value));
                },
              ),
              StarSettingsSwitchItem(
                label: l10n.audioAndVideoAutomaticGainControlLabel,
                description: l10n.audioAndVideoAutomaticGainControlDescription,
                value: settings.autoGainControl,
                enabled:
                    !(settings.noiseSuppressionTier ==
                            NoiseSuppressionTier.enhanced &&
                        noiseFilterSupported),
                onChanged: (bool value) {
                  unawaited(settingsNotifier.setAutoGainControl(value: value));
                },
              ),
            ],
          ),
      ],
    );
  }
}
