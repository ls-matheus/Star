import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:star_app/core/providers/app/account_user_id.dart';
import 'package:star_app/features/settings/domain/user_settings_section.dart';
import 'package:star_app/features/settings/utils/commerce/open_user_billing_settings.dart';
import 'package:star_app/features/shell/data/nagbar_user_updates.dart';
import 'package:star_app/features/shell/presentation/responsive_layout.dart';
import 'package:star_app/features/shell/presentation/widgets/nagbars/nagbar_widget.dart';
import 'package:star_app/features/shell/providers/nagbar/nagbar_providers.dart';
import 'package:star_app/features/shell/providers/user/current_user_private_provider.dart';
import 'package:star_app/features/ui/nagbar/star_nagbar.dart';
import 'package:star_app/features/ui/nagbar/star_nagbar_button.dart';
import 'package:star_app/features/ui/nagbar/star_nagbar_content.dart';
import 'package:star_app/l10n/generated/star_localizations.dart';
import 'package:star_app/material_ui.dart';

class GiftInventoryNagbar extends ConsumerWidget implements NagbarWidget {
  const GiftInventoryNagbar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = StarLocalizations.of(context);
    final user = ref.watch(
      currentUserPrivateReadProvider(watchAccountUserId(ref)),
    );
    final count = user?.unreadGiftInventoryCount ?? 1;
    final isMobile = isMobileLayout(context);
    final message = count <= 1
        ? l10n.nagbarGiftInventoryOne
        : l10n.nagbarGiftInventoryMany(count);

    Future<void> dismiss() async {
      await ref.read(nagbarDismissalsProvider.notifier).dismissGiftInventory();
      await clearUnreadGiftInventoryFlag(ref);
    }

    return StarNagbar(
      isMobile: isMobile,
      backgroundColor: Theme.of(context).colorScheme.primary,
      textColor: Colors.white,
      dismissible: true,
      onDismiss: dismiss,
      child: StarNagbarContent(
        isMobile: isMobile,
        message: message,
        onDismiss: dismiss,
        actions: StarNagbarButton(
          isMobile: isMobile,
          label: l10n.nagbarViewGiftInventory,
          onPressed: () => openUserBillingSettings(
            context,
            UserSettingsSection.giftsAndCodes,
          ),
        ),
      ),
    );
  }
}
