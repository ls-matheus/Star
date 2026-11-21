import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:star_app/core/providers/instance/instance_runtime_config_provider.dart';
import 'package:star_app/features/settings/providers/view_models/user_settings_view_model.dart';
import 'package:star_app/features/settings/utils/resend_verification_email.dart';
import 'package:star_app/features/shell/presentation/responsive_layout.dart';
import 'package:star_app/features/shell/presentation/widgets/nagbars/nagbar_widget.dart';
import 'package:star_app/features/ui/nagbar/star_nagbar.dart';
import 'package:star_app/features/ui/nagbar/star_nagbar_button.dart';
import 'package:star_app/features/ui/nagbar/star_nagbar_content.dart';
import 'package:star_app/l10n/generated/star_localizations.dart';
import 'package:star_app/material_ui.dart';

class EmailVerificationNagbar extends ConsumerWidget implements NagbarWidget {
  const EmailVerificationNagbar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final StarLocalizations l10n = StarLocalizations.of(context);
    final UserSettingsViewState settings = ref.watch(
      userSettingsViewModelProvider,
    );
    final bool isMobile = isMobileLayout(context);
    final bool emailsEnabled = ref.watch(
      instanceRuntimeConfigProvider.select((config) => config.emailsEnabled),
    );
    final bool sending = ref.watch(resendVerificationEmailInFlightProvider);
    final String displayName = settings.displayName.trim().isNotEmpty
        ? settings.displayName
        : settings.username;
    return StarNagbar(
      isMobile: isMobile,
      backgroundColor: const Color(0xFFEA580C),
      textColor: Colors.white,
      child: StarNagbarContent(
        isMobile: isMobile,
        message: l10n.nagbarEmailVerificationMessage(displayName),
        actions: emailsEnabled
            ? StarNagbarButton(
                isMobile: isMobile,
                label: l10n.verificationResendEmail,
                isLoading: sending,
                onPressed: sending
                    ? null
                    : () => resendVerificationEmail(ref, context),
              )
            : null,
      ),
    );
  }
}
