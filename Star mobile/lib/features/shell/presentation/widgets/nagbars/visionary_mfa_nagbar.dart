import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:star_app/features/settings/presentation/user_settings_modal.dart';
import 'package:star_app/features/shell/presentation/responsive_layout.dart';
import 'package:star_app/features/shell/presentation/widgets/nagbars/nagbar_widget.dart';
import 'package:star_app/features/shell/providers/nagbar/nagbar_providers.dart';
import 'package:star_app/features/ui/nagbar/star_nagbar.dart';
import 'package:star_app/features/ui/nagbar/star_nagbar_button.dart';
import 'package:star_app/features/ui/nagbar/star_nagbar_content.dart';
import 'package:star_app/l10n/generated/star_localizations.dart';
import 'package:star_app/material_ui.dart';

class VisionaryMfaNagbar extends ConsumerWidget implements NagbarWidget {
  const VisionaryMfaNagbar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final StarLocalizations l10n = StarLocalizations.of(context);
    final bool isMobile = isMobileLayout(context);
    return StarNagbar(
      isMobile: isMobile,
      backgroundColor: const Color(0xFFEA580C),
      textColor: Colors.white,
      dismissible: true,
      onDismiss: () =>
          ref.read(nagbarDismissalsProvider.notifier).dismissVisionaryMfa(),
      child: StarNagbarContent(
        isMobile: isMobile,
        message: l10n.nagbarVisionaryMfa,
        onDismiss: () =>
            ref.read(nagbarDismissalsProvider.notifier).dismissVisionaryMfa(),
        actions: StarNagbarButton(
          isMobile: isMobile,
          label: l10n.nagbarEnableMfa,
          onPressed: () =>
              UserSettingsModal.show(context, openSecuritySection: true),
        ),
      ),
    );
  }
}
