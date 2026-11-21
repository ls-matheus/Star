import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:star_app/core/theme/star_theme_extension.dart';
import 'package:star_app/features/auth/presentation/sheets/account_switcher_sheet.dart';
import 'package:star_app/features/auth/providers/account_manager_provider.dart';
import 'package:star_app/features/profile/domain/presence_status_labels.dart';
import 'package:star_app/features/profile/presentation/sheets/status_change_sheet.dart';
import 'package:star_app/features/profile/providers/user_presence_provider.dart';
import 'package:star_app/features/settings/providers/view_models/user_settings_view_model.dart';
import 'package:star_app/features/ui/bottom_sheet/star_bottom_sheet.dart';
import 'package:star_app/features/ui/status_indicator/star_status_indicator.dart';
import 'package:star_app/l10n/generated/star_localizations.dart';
import 'package:star_app/material_ui.dart';
import 'package:star_app/shared/icons/phosphor.dart';

class ProfileTabMenuSheet {
  ProfileTabMenuSheet._();

  static Future<void> show(BuildContext context, WidgetRef ref) async {
    unawaited(ref.read(accountManagerProvider.notifier).loadAccounts());

    await StarBottomSheet.show<void>(
      context,
      variant: StarBottomSheetVariant.menu,
      useRootNavigator: true,
      builder: (sheetContext, close) {
        return StarBottomSheetContent(
          scrollable: false,
          child: ProfileTabMenuSheetBody(
            onOpenStatus: () {
              close();
              unawaited(StatusChangeSheet.show(sheetContext));
            },
            onOpenAccounts: () {
              close();
              unawaited(AccountSwitcherSheet.show(sheetContext));
            },
          ),
        );
      },
    );
  }
}

class ProfileTabMenuSheetBody extends ConsumerWidget {
  const ProfileTabMenuSheetBody({
    required this.onOpenStatus,
    required this.onOpenAccounts,
    super.key,
  });

  final VoidCallback onOpenStatus;
  final VoidCallback onOpenAccounts;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final StarLocalizations l10n = StarLocalizations.of(context);
    final UserSettingsViewState user = ref.watch(userSettingsViewModelProvider);
    final String? selfUserId = user.userId.isEmpty ? null : user.userId;
    final String status = selfUserId == null
        ? 'online'
        : ref.watch(userPresenceProvider(selfUserId))?.status ?? 'online';

    return StarBottomSheetGroupColumn(
      children: [
        StarMenuGroup(
          children: [
            StarBottomSheetMenuItem(
              label: presenceStatusLabel(status, l10n),
              leading: StarStatusIndicator(status: status, size: 14),
              trailing: PhosphorIcon(
                PhosphorIconsBold.caretRight,
                size: 20,
                color: context.colors.textPrimaryMuted,
              ),
              onTap: onOpenStatus,
            ),
            StarBottomSheetSubmenuItem(
              label: l10n.profileTabMenuSwitchAccounts,
              icon: PhosphorIconsBold.users,
              onTap: onOpenAccounts,
            ),
          ],
        ),
      ],
    );
  }
}
