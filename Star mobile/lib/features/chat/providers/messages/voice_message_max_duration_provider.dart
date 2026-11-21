import 'package:star_app/core/limits/limit_context.dart';
import 'package:star_app/core/limits/limit_defaults.dart';
import 'package:star_app/core/limits/limit_key.dart';
import 'package:star_app/core/limits/limit_resolver.dart';
import 'package:star_app/core/limits/limit_types.dart';
import 'package:star_app/core/providers/instance/well_known_provider.dart';
import 'package:star_dart/export.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'voice_message_max_duration_provider.g.dart';

@Riverpod(keepAlive: true)
int maxVoiceMessageDurationSeconds(Ref ref) {
  final LimitMatchContext context = ref.watch(currentUserLimitContextProvider);
  final int fallback =
      kDefaultFreeLimits[LimitKeys.maxVoiceMessageDuration] ?? 1200;
  final AsyncValue<WellKnownStarResponse> wellKnown = ref.watch(
    wellKnownProvider,
  );
  return wellKnown.when(
    data: (WellKnownStarResponse response) => resolveInstanceLimit(
      limits: response.limits,
      key: LimitKeys.maxVoiceMessageDuration,
      context: context,
      fallback: fallback,
    ),
    loading: () => fallback,
    error: (_, _) => fallback,
  );
}
