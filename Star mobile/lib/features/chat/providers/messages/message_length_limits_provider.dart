import 'package:star_app/core/limits/limit_context.dart';
import 'package:star_app/core/limits/limit_defaults.dart';
import 'package:star_app/core/limits/limit_key.dart';
import 'package:star_app/core/limits/limit_resolver.dart';
import 'package:star_app/core/limits/limit_types.dart';
import 'package:star_app/core/premium/current_user_entitlements_provider.dart';
import 'package:star_app/core/providers/instance/active_instance_provider.dart';
import 'package:star_app/core/providers/instance/well_known_provider.dart';
import 'package:star_app/features/chat/utils/messages/message_length_constants.dart';
import 'package:star_dart/export.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'message_length_limits_provider.g.dart';

WellKnownStarResponse? _cachedOrLiveWellKnown(Ref ref) {
  final AsyncValue<WellKnownStarResponse> wellKnown = ref.watch(
    wellKnownProvider,
  );
  return wellKnown.maybeWhen(
    data: (WellKnownStarResponse response) => response,
    orElse: () => ref.watch(activeInstanceProvider).wellKnown,
  );
}

int _resolveMaxMessageLength({
  required WellKnownStarResponse? wellKnown,
  required LimitMatchContext context,
  required int fallback,
}) {
  if (wellKnown == null) {
    return fallback;
  }
  return resolveInstanceLimit(
    limits: wellKnown.limits,
    key: LimitKeys.maxMessageLength,
    context: context,
    fallback: fallback,
  );
}

@Riverpod(keepAlive: true)
int maxMessageLength(Ref ref) {
  final bool isPremium = ref.watch(isEffectivelyPremiumProvider);
  final int fallback = resolveMaxMessageLength(isPremium: isPremium);
  return _resolveMaxMessageLength(
    wellKnown: _cachedOrLiveWellKnown(ref),
    context: ref.watch(currentUserLimitContextProvider),
    fallback: fallback,
  );
}

@Riverpod(keepAlive: true)
int premiumMaxMessageLength(Ref ref) {
  return _resolveMaxMessageLength(
    wellKnown: _cachedOrLiveWellKnown(ref),
    context: buildUserLimitContext(traits: const <String>['premium']),
    fallback: kMaxMessageLengthPremium,
  );
}
