import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:star_app/core/router/route_kind.dart';
import 'package:star_app/core/router/route_state_providers.dart';
import 'package:star_app/features/shell/presentation/responsive_layout.dart';
import 'package:star_app/features/voice/providers/voice_session_provider.dart';
import 'package:star_app/features/voice/utils/pip/pip_visibility.dart';
import 'package:star_app/material_ui.dart';

const Duration kVoiceCallPhoneTransitionDuration = Duration(milliseconds: 420);
const Curve kVoiceCallPhoneTransitionCurve = Curves.easeOutCubic;
const Offset kVoiceCallPhoneSlideBegin = Offset(0, 0.12);

bool shouldMinimizePhoneVoiceCall(BuildContext context, WidgetRef ref) {
  if (!isHandheldVoiceOverlay(context)) {
    return false;
  }
  final String location = ref.read(shellLocationProvider);
  return voicePipIsOnSessionCallRoute(
    voice: ref.read(voiceSessionProvider),
    location: location,
    routeGuildId: extractGuildId(location),
    routeChannelId: extractChannelId(location),
  );
}
