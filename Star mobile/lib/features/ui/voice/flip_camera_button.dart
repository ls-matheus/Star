import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:star_app/core/gateway/providers/gateway_event_providers.dart';
import 'package:star_app/features/ui/button/star_button.dart';
import 'package:star_app/features/ui/button/star_button_size.dart';
import 'package:star_app/features/ui/button/star_button_variant.dart';
import 'package:star_app/features/voice/providers/voice_session_provider.dart';
import 'package:star_app/features/voice/providers/voice_session_state.dart';
import 'package:star_app/features/voice/utils/media/camera_platform.dart';
import 'package:star_app/l10n/generated/star_localizations.dart';
import 'package:star_app/material_ui.dart';
import 'package:star_app/shared/icons/phosphor.dart';
import 'package:star_dart/gateway.dart';

class FlipCameraButton extends ConsumerWidget {
  const FlipCameraButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!isMobileVoiceCameraPlatform()) {
      return const SizedBox.shrink();
    }
    final StarLocalizations l10n = StarLocalizations.of(context);
    final (bool isConnected, String? connectionId) = ref.watch(
      voiceSessionProvider.select(
        (VoiceSessionState s) => (s.isConnected, s.activeConnectionId),
      ),
    );
    if (!isConnected || connectionId == null) {
      return const SizedBox.shrink();
    }
    final VoiceState? selfVs = ref.watch(
      voiceStateForConnectionProvider(connectionId),
    );
    final bool isVideoOn = selfVs?.selfVideo ?? false;
    if (!isVideoOn) {
      return const SizedBox.shrink();
    }
    return StarButton.circle(
      icon: PhosphorIconsFill.cameraRotate,
      variant: StarButtonVariant.secondary,
      size: StarButtonSize.small,
      iconSize: 20,
      semanticLabel: l10n.voiceControlFlipCamera,
      onPressed: () {
        unawaited(ref.read(voiceSessionProvider.notifier).flipCamera());
      },
    );
  }
}
