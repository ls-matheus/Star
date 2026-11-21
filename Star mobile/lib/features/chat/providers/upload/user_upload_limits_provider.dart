import 'package:star_app/core/limits/limit_context.dart';
import 'package:star_app/core/limits/limit_key.dart';
import 'package:star_app/core/limits/limit_resolver.dart';
import 'package:star_app/core/limits/limit_types.dart';
import 'package:star_app/core/premium/current_user_entitlements_provider.dart';
import 'package:star_app/core/providers/instance/well_known_provider.dart';
import 'package:star_app/features/chat/utils/attachments/file_upload_constants.dart';
import 'package:star_dart/export.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'user_upload_limits_provider.g.dart';

@Riverpod(keepAlive: true)
int maxAttachmentFileBytes(Ref ref) {
  final bool isPremium = ref.watch(isEffectivelyPremiumProvider);
  final int fallback = resolveMaxAttachmentFileBytes(isPremium: isPremium);
  final LimitMatchContext context = ref.watch(currentUserLimitContextProvider);
  final AsyncValue<WellKnownStarResponse> wellKnown = ref.watch(
    wellKnownProvider,
  );
  return wellKnown.when(
    data: (WellKnownStarResponse response) => resolveInstanceLimit(
      limits: response.limits,
      key: LimitKeys.maxAttachmentFileSize,
      context: context,
      fallback: fallback,
    ),
    loading: () => fallback,
    error: (_, _) => fallback,
  );
}
