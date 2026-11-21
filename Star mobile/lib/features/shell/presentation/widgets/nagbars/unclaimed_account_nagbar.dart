import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:star_app/features/settings/presentation/sheets/claim_account_sheet.dart';
import 'package:star_app/features/settings/providers/view_models/user_settings_view_model.dart';
import 'package:star_app/features/shell/presentation/responsive_layout.dart';
import 'package:star_app/features/shell/presentation/widgets/nagbars/nagbar_widget.dart';
import 'package:star_app/features/ui/nagbar/star_nagbar.dart';
import 'package:star_app/features/ui/nagbar/star_nagbar_button.dart';
import 'package:star_app/features/ui/nagbar/star_nagbar_content.dart';
import 'package:star_app/l10n/generated/star_localizations.dart';
import 'package:star_app/material_ui.dart';

class UnclaimedAccountNagbar extends ConsumerWidget implements NagbarWidget {
  const UnclaimedAccountNagbar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final StarLocalizations l10n = StarLocalizations.of(context);
    final UserSettingsViewState settings = ref.watch(
      userSettingsViewModelProvider,
    );
    final bool isMobile = isMobileLayout(context);
    final String displayName = settings.displayName.trim().isNotEmpty
        ? settings.displayName
        : settings.username;
    return StarNagbar(
      isMobile: isMobile,
      backgroundColor: const Color(0xFFEA580C),
      textColor: Colors.white,
      child: StarNagbarContent(
        isMobile: isMobile,
        message: l10n.nagbarUnclaimedAccountMessage(displayName),
        actions: StarNagbarButton(
          isMobile: isMobile,
          label: l10n.claimAccount,
          onPressed: () => ClaimAccountSheet.show(context, ref),
        ),
      ),
    );
  }
}
