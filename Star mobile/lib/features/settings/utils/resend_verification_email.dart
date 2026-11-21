import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:star_app/core/api/star_client_provider.dart';
import 'package:star_app/features/ui/toast/star_toast.dart';
import 'package:star_app/features/ui/toast/toast_provider.dart';
import 'package:star_app/l10n/generated/star_localizations.dart';
import 'package:star_app/material_ui.dart';
import 'package:star_app/shared/utils/api_error_presentation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'resend_verification_email.g.dart';

@Riverpod(keepAlive: true)
class ResendVerificationEmailInFlight
    extends _$ResendVerificationEmailInFlight {
  @override
  bool build() => false;

  void setInFlight({required bool value}) {
    if (state == value) {
      return;
    }
    state = value;
  }
}

Future<void> resendVerificationEmail(
  WidgetRef ref,
  BuildContext context,
) async {
  if (ref.read(resendVerificationEmailInFlightProvider)) {
    return;
  }
  final StarLocalizations l10n = StarLocalizations.of(context);
  final ResendVerificationEmailInFlight inFlight = ref.read(
    resendVerificationEmailInFlightProvider.notifier,
  )..setInFlight(value: true);
  final Toast toasts = ref.read(toastProvider.notifier);
  try {
    await ref.read(starClientProvider).auth.resendVerificationEmail();
    toasts.show(
      StarToast(
        message: l10n.verificationEmailSent,
        variant: StarToastVariant.success,
      ),
    );
  } on DioException catch (error) {
    if (error.response?.statusCode == 429) {
      toasts.show(
        StarToast(
          message: l10n.verificationEmailRateLimited,
          variant: StarToastVariant.danger,
        ),
      );
      return;
    }
    if (context.mounted) {
      await showApiError(context, ApiErrorAction.generic, error);
    }
  } finally {
    inFlight.setInFlight(value: false);
  }
}
