import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:star_app/features/settings/providers/preferences/voice_settings_provider.dart';
import 'package:star_app/features/ui/ui.dart';
import 'package:star_app/features/voice/domain/voice_settings_state.dart';
import 'package:star_app/features/voice/presentation/widgets/voice_call_desktop_hud/voice_call_hud_menu.dart';
import 'package:star_app/features/voice/providers/active_self_voice_state_provider.dart';
import 'package:star_app/features/voice/providers/voice_media_devices_provider.dart';
import 'package:star_app/features/voice/providers/voice_session_provider.dart';
import 'package:star_app/features/voice/utils/media/voice_media_device_label.dart';
import 'package:star_app/l10n/generated/star_localizations.dart';
import 'package:star_app/material_ui.dart';
import 'package:star_app/shared/icons/phosphor.dart';
import 'package:star_dart/gateway.dart';

enum VoiceCallHudDeviceKind { input, output, camera }

const List<VoiceMediaDeviceOption> _kDefaultDeviceOnly =
    <VoiceMediaDeviceOption>[
      VoiceMediaDeviceOption(deviceId: kDefaultVoiceDeviceId, label: ''),
    ];

class VoiceCallHudDeviceMenu extends ConsumerWidget {
  const VoiceCallHudDeviceMenu({
    required this.kind,
    required this.onClose,
    required this.onOpenSettings,
    super.key,
  });

  final VoiceCallHudDeviceKind kind;
  final VoidCallback onClose;
  final VoidCallback onOpenSettings;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final StarLocalizations l10n = StarLocalizations.of(context);
    final VoiceSettingsState settings = ref.watch(voiceSettingsProvider);
    final VoiceSettings settingsNotifier = ref.read(
      voiceSettingsProvider.notifier,
    );
    final VoiceMediaDevicesState devices = ref.watch(voiceMediaDevicesProvider);
    final VoiceState? selfState = ref.watch(activeSelfVoiceStateProvider);
    final VoiceSession session = ref.read(voiceSessionProvider.notifier);
    final (
      String header,
      List<VoiceMediaDeviceOption> options,
      String selectedId,
      Future<void> Function(String) select,
    ) = switch (kind) {
      VoiceCallHudDeviceKind.input => (
        l10n.audioAndVideoInputDeviceLabel,
        devices.audioInputs,
        settings.inputDeviceId,
        settingsNotifier.setInputDeviceId,
      ),
      VoiceCallHudDeviceKind.output => (
        l10n.audioAndVideoOutputDeviceLabel,
        devices.audioOutputs,
        settings.outputDeviceId,
        settingsNotifier.setOutputDeviceId,
      ),
      VoiceCallHudDeviceKind.camera => (
        l10n.audioAndVideoCameraLabel,
        devices.videoInputs,
        settings.videoDeviceId,
        settingsNotifier.setVideoDeviceId,
      ),
    };
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        StarMenuSectionHeader(label: header),
        for (final VoiceMediaDeviceOption device
            in options.isEmpty ? _kDefaultDeviceOnly : options)
          StarMenuRadioItem(
            label: voiceMediaDeviceLabel(l10n, device),
            isSelected: device.deviceId == selectedId,
            onPressed: () {
              unawaited(select(device.deviceId));
              onClose();
            },
          ),
        const StarMenuDivider(),
        switch (kind) {
          VoiceCallHudDeviceKind.input => StarMenuCheckboxItem(
            label: l10n.voiceControlMute,
            isChecked: selfState?.selfMute ?? false,
            onPressed: () => unawaited(session.toggleSelfMute()),
          ),
          VoiceCallHudDeviceKind.output => StarMenuCheckboxItem(
            label: l10n.voiceControlDeafen,
            isChecked: selfState?.selfDeaf ?? false,
            onPressed: () => unawaited(session.toggleSelfDeafen()),
          ),
          VoiceCallHudDeviceKind.camera => StarMenuCheckboxItem(
            label: l10n.audioAndVideoMirrorCameraLabel,
            isChecked: settings.mirrorCamera,
            onPressed: () => unawaited(
              settingsNotifier.setMirrorCamera(value: !settings.mirrorCamera),
            ),
          ),
        },
        const StarMenuDivider(),
        VoiceCallHudMenuSettingsItem(
          onClose: onClose,
          onOpenSettings: onOpenSettings,
        ),
      ],
    );
  }
}

class VoiceCallHudScreenShareMenu extends ConsumerWidget {
  const VoiceCallHudScreenShareMenu({
    required this.onClose,
    required this.onToggle,
    required this.onOpenSettings,
    super.key,
  });

  final VoidCallback onClose;
  final VoidCallback onToggle;
  final VoidCallback onOpenSettings;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final StarLocalizations l10n = StarLocalizations.of(context);
    final bool isSharing =
        ref.watch(activeSelfVoiceStateProvider)?.selfStream ?? false;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        StarMenuItem(
          label: isSharing
              ? l10n.voiceControlStopScreenShare
              : l10n.voiceControlStartScreenShare,
          icon: isSharing ? PhosphorIconsFill.x : PhosphorIconsFill.monitorPlay,
          isDanger: isSharing,
          onPressed: () {
            onClose();
            onToggle();
          },
        ),
        const StarMenuDivider(),
        VoiceCallHudMenuSettingsItem(
          onClose: onClose,
          onOpenSettings: onOpenSettings,
        ),
      ],
    );
  }
}
