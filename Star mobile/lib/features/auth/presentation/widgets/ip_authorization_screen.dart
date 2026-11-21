import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:star_app/core/theme/star_theme_extension.dart';
import 'package:star_app/features/auth/domain/ip_authorization_challenge.dart';
import 'package:star_app/features/auth/providers/ip_authorization_view_model.dart';
import 'package:star_app/features/ui/button/star_button.dart';
import 'package:star_app/l10n/generated/star_localizations.dart';
import 'package:star_app/material_ui.dart';
import 'package:star_app/shared/icons/phosphor.dart';

class IpAuthorizationScreen extends ConsumerWidget {
  const IpAuthorizationScreen({
    required this.challenge,
    required this.onAuthorized,
    required this.onBack,
    super.key,
  });

  final IpAuthorizationChallenge challenge;
  final VoidCallback onAuthorized;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vm = ref.watch(
      ipAuthorizationViewModelProvider(
        challenge.ticket,
        challenge.resendAvailableIn,
      ),
    );
    final notifier = ref.read(
      ipAuthorizationViewModelProvider(
        challenge.ticket,
        challenge.resendAvailableIn,
      ).notifier,
    );

    ref.listen(
      ipAuthorizationViewModelProvider(
        challenge.ticket,
        challenge.resendAvailableIn,
      ),
      (_, next) {
        if (next.completedSession != null) {
          onAuthorized();
        }
      },
    );

    final strings = StarLocalizations.of(context);
    final colors = context.colors;
    final layout = context.layout;
    final state = vm.pollingState;
    final (IconData icon, String title, String description) = switch (state) {
      IpAuthPollingState.polling => (
        PhosphorIconsFill.envelopeSimple,
        strings.ipAuthCheckEmail,
        strings.ipAuthDescription(challenge.email),
      ),
      IpAuthPollingState.error => (
        PhosphorIconsFill.warningCircle,
        strings.ipAuthConnectionLost,
        strings.ipAuthConnectionLostDescription,
      ),
      IpAuthPollingState.expired => (
        PhosphorIconsFill.warningCircle,
        strings.ipAuthLinkExpired,
        strings.ipAuthLinkExpiredDescription,
      ),
    };

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 48,
          color: state == IpAuthPollingState.polling
              ? colors.textPrimary
              : colors.textDanger,
        ),
        SizedBox(height: layout.s4),
        Text(
          title,
          style: context.textStyles.heading,
          textAlign: TextAlign.center,
        ),
        SizedBox(height: layout.s2),
        Text(
          description,
          style: context.textStyles.bodySmall.copyWith(
            color: colors.textPrimaryMuted,
          ),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: layout.s6),
        if (state == IpAuthPollingState.error)
          StarButton.primary(onPressed: notifier.retry, label: strings.retry)
        else if (state == IpAuthPollingState.polling)
          StarButton.secondary(
            onPressed: vm.resendIn > 0 || vm.resendUsed
                ? null
                : notifier.resend,
            label: _resendLabel(strings, vm),
          ),
        if (state != IpAuthPollingState.expired) SizedBox(height: layout.s2),
        StarButton.secondary(onPressed: onBack, label: strings.back),
      ],
    );
  }

  String _resendLabel(StarLocalizations strings, IpAuthViewState vm) {
    final base = vm.resendUsed
        ? strings.ipAuthResent
        : strings.ipAuthResendEmail;
    if (vm.resendIn > 0) {
      return '$base (${strings.ipAuthResendCountdown(vm.resendIn)})';
    }
    return base;
  }
}
