import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:star_app/core/providers/instance/instance_runtime_config_provider.dart';
import 'package:star_app/features/settings/presentation/sheets/messaging_paused_help_sheet.dart';
import 'package:star_app/features/shell/presentation/responsive_layout.dart';
import 'package:star_app/features/shell/presentation/widgets/nagbars/nagbar_widget.dart';
import 'package:star_app/features/ui/nagbar/star_nagbar.dart';
import 'package:star_app/features/ui/nagbar/star_nagbar_button.dart';
import 'package:star_app/features/ui/nagbar/star_nagbar_content.dart';
import 'package:star_app/l10n/generated/star_localizations.dart';
import 'package:star_app/material_ui.dart';

class AccountLimitedNagbar extends ConsumerWidget implements NagbarWidget {
  const AccountLimitedNagbar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final StarLocalizations l10n = StarLocalizations.of(context);
    final bool isMobile = isMobileLayout(context);
    final bool selfHosted = ref.watch(
      instanceRuntimeConfigProvider.select((config) => config.selfHosted),
    );
    return StarNagbar(
      isMobile: isMobile,
      backgroundColor: const Color(0xFF4E5058),
      textColor: Colors.white,
      child: StarNagbarContent(
        isMobile: isMobile,
        message: l10n.accountLimitedNotice,
        actions: selfHosted
            ? null
            : StarNagbarButton(
                isMobile: isMobile,
                label: l10n.messagingPausedTextDidNotGoThrough,
                onPressed: () => MessagingPausedHelpSheet.show(context),
              ),
      ),
    );
  }
}
