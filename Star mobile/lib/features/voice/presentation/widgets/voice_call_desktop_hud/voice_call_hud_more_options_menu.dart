import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:star_app/features/settings/providers/preferences/voice_settings_provider.dart';
import 'package:star_app/features/ui/ui.dart';
import 'package:star_app/features/ui/voice/voice_channel_control_panel_settings.dart';
import 'package:star_app/features/voice/domain/voice_settings_state.dart';
import 'package:star_app/features/voice/presentation/widgets/voice_call_desktop_hud/voice_call_hud_menu.dart';
import 'package:star_app/features/voice/providers/voice_call_display_preferences_provider.dart';
import 'package:star_app/features/voice/providers/voice_call_layout_provider.dart';
import 'package:star_app/features/voice/providers/voice_session_provider.dart';
import 'package:star_app/features/voice/providers/voice_session_state.dart';
import 'package:star_app/l10n/generated/star_localizations.dart';
import 'package:star_app/material_ui.dart';
import 'package:star_app/shared/icons/phosphor.dart';

class VoiceCallHudMoreOptionsMenu extends ConsumerWidget {
  const VoiceCallHudMoreOptionsMenu({
    required this.onClose,
    required this.onSwitchToStandard,
    required this.onCopyDiagnostics,
    required this.onOpenSettings,
    super.key,
  });

  final VoidCallback onClose;
  final VoidCallback onSwitchToStandard;
  final VoidCallback onCopyDiagnostics;
  final VoidCallback onOpenSettings;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final StarLocalizations l10n = StarLocalizations.of(context);
    final VoiceSettingsState settings = ref.watch(voiceSettingsProvider);
    final VoiceCallDisplayPreferencesState display = ref.watch(
      voiceCallDisplayPreferencesProvider,
    );
    final VoiceCallDisplayPreferences displayNotifier = ref.read(
      voiceCallDisplayPreferencesProvider.notifier,
    );
    final VoiceCallLayoutMode mode = ref.watch(
      voiceCallLayoutProvider.select((VoiceCallLayoutState s) => s.mode),
    );
    final VoiceCallLayout layoutNotifier = ref.read(
      voiceCallLayoutProvider.notifier,
    );
    final (NoiseSuppressionTier tier, bool noiseFilterSupported) =
        watchVoicePanelNoiseSuppression(ref);
    final bool showSwitchToStandard = watchCanSwitchToStandardVoiceCall(
      ref,
      channelId: ref.watch(
        voiceSessionProvider.select((VoiceSessionState s) => s.channelId),
      ),
    );

    void selectNoiseTier(NoiseSuppressionTier value) {
      unawaited(setVoicePanelNoiseSuppressionTier(ref, value));
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        StarMenuSectionHeader(label: l10n.voiceCallViewModeLabel),
        StarMenuRadioItem(
          label: l10n.voiceCallViewModeGrid,
          isSelected: mode == VoiceCallLayoutMode.grid,
          onPressed: () => layoutNotifier.setMode(VoiceCallLayoutMode.grid),
        ),
        StarMenuRadioItem(
          label: l10n.voiceCallViewModeFocus,
          isSelected: mode == VoiceCallLayoutMode.focus,
          onPressed: () => layoutNotifier.setMode(VoiceCallLayoutMode.focus),
        ),
        const StarMenuDivider(),
        StarMenuCheckboxItem(
          label: l10n.voicePanelOnlyShowVideosLabel,
          isChecked: display.onlyShowVideos,
          onPressed: () =>
              displayNotifier.setOnlyShowVideos(value: !display.onlyShowVideos),
        ),
        StarMenuCheckboxItem(
          label: l10n.voicePanelShowOwnCameraLabel,
          isChecked: display.showOwnCamera,
          onPressed: () =>
              displayNotifier.setShowOwnCamera(value: !display.showOwnCamera),
        ),
        StarMenuCheckboxItem(
          label: l10n.voicePrioritizeSpeakersLabel,
          isChecked: settings.prioritizeSpeakingParticipants,
          onPressed: () => unawaited(
            ref
                .read(voiceSettingsProvider.notifier)
                .setPrioritizeSpeakingParticipants(
                  value: !settings.prioritizeSpeakingParticipants,
                ),
          ),
        ),
        const StarMenuDivider(),
        StarMenuSectionHeader(
          label: l10n.audioAndVideoNoiseSuppressionSectionTitle,
        ),
        StarMenuRadioItem(
          label: l10n.audioAndVideoNoiseSuppressionEnhancedLabel,
          isSelected: tier == NoiseSuppressionTier.enhanced,
          enabled: noiseFilterSupported,
          onPressed: () => selectNoiseTier(NoiseSuppressionTier.enhanced),
        ),
        StarMenuRadioItem(
          label: l10n.audioAndVideoNoiseSuppressionStandardLabel,
          isSelected: tier == NoiseSuppressionTier.standard,
          onPressed: () => selectNoiseTier(NoiseSuppressionTier.standard),
        ),
        StarMenuRadioItem(
          label: l10n.audioAndVideoNoiseSuppressionNoneLabel,
          isSelected: tier == NoiseSuppressionTier.none,
          onPressed: () => selectNoiseTier(NoiseSuppressionTier.none),
        ),
        const StarMenuDivider(),
        if (showSwitchToStandard)
          StarMenuItem(
            label: l10n.voiceP2pSwitchToStandard,
            icon: PhosphorIconsFill.shareNetwork,
            onPressed: () {
              onClose();
              onSwitchToStandard();
            },
          ),
        StarMenuItem(
          label: l10n.voiceDiagnosticsCopy,
          icon: PhosphorIconsFill.chartLine,
          onPressed: () {
            onClose();
            onCopyDiagnostics();
          },
        ),
        VoiceCallHudMenuSettingsItem(
          onClose: onClose,
          onOpenSettings: onOpenSettings,
        ),
      ],
    );
  }
}
