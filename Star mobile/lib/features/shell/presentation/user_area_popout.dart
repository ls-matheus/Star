import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:star_app/core/constants/media_proxy_sizes.dart';
import 'package:star_app/core/media/star_media_url.dart';
import 'package:star_app/core/theme/star_theme_extension.dart';
import 'package:star_app/features/auth/presentation/sheets/account_switcher_sheet.dart';
import 'package:star_app/features/auth/providers/account_manager_provider.dart';
import 'package:star_app/features/chat/presentation/widgets/messages/message_markdown.dart';
import 'package:star_app/features/profile/domain/custom_status_utils.dart';
import 'package:star_app/features/profile/domain/presence_status_labels.dart';
import 'package:star_app/features/profile/presentation/sheets/custom_status_sheet.dart';
import 'package:star_app/features/profile/presentation/sheets/status_change_sheet.dart';
import 'package:star_app/features/profile/presentation/user_profile_sheet.dart';
import 'package:star_app/features/profile/presentation/widgets/status_flyout_menu.dart';
import 'package:star_app/features/profile/presentation/widgets/user_profile_custom_status.dart';
import 'package:star_app/features/profile/presentation/widgets/user_profile_identity_avatar.dart';
import 'package:star_app/features/profile/presentation/widgets/user_profile_popout_frame.dart';
import 'package:star_app/features/profile/providers/own_profile_badges_provider.dart';
import 'package:star_app/features/profile/providers/user_presence_provider.dart';
import 'package:star_app/features/profile/providers/user_settings_status_provider.dart';
import 'package:star_app/features/settings/presentation/user_settings_modal.dart';
import 'package:star_app/features/ui/bottom_sheet/star_bottom_sheet.dart';
import 'package:star_app/features/ui/button/star_button.dart';
import 'package:star_app/features/ui/desktop_surface/star_desktop_surface.dart';
import 'package:star_app/features/ui/status_indicator/star_status_indicator.dart';
import 'package:star_app/features/ui/tappable/star_tappable.dart';
import 'package:star_app/features/voice/providers/voice_session_provider.dart';
import 'package:star_app/features/voice/providers/voice_session_state.dart';
import 'package:star_app/features/voice/utils/voice_diagnostics_report.dart';
import 'package:star_app/l10n/generated/star_localizations.dart';
import 'package:star_app/material_ui.dart';
import 'package:star_app/shared/icons/phosphor.dart';
import 'package:star_app/shared/providers/input_modality_provider.dart';
import 'package:star_app/shared/providers/user_profile.dart';
import 'package:star_app/shared/utils/clipboard_utils.dart';
import 'package:star_app/shared/utils/guild_user_display.dart';
import 'package:star_app/shared/utils/user_tag.dart';
import 'package:star_dart/export.dart';
import 'package:star_markdown/star_markdown.dart';

part 'widgets/user_area_popout_card.dart';

class UserAreaPopout {
  UserAreaPopout._();

  static Future<void> _showDesktop(BuildContext context) {
    return StarBottomSheet.show<void>(
      context,
      useRootNavigator: true,
      desktop: StarDesktopPresentation(
        surface: StarDesktopSurface.popout,
        width: kUserProfilePopoutWidth,
        placement: StarDesktopPlacement.aboveStart,
        anchorContext: context,
        showPanelBorder: false,
        borderRadius: 6,
      ),
      builder: (BuildContext sheetContext, VoidCallback close) =>
          _DesktopUserAreaCard(onClose: close),
    );
  }

  static Future<void> show(BuildContext context, WidgetRef ref) {
    unawaited(ref.read(accountManagerProvider.notifier).loadAccounts());
    final StarLocalizations l10n = StarLocalizations.of(context);
    if (usesDesktopPointerUi(context)) {
      return _showDesktop(context);
    }
    return StarBottomSheet.show<void>(
      context,
      title: l10n.statusChangeSheetTitle,
      variant: StarBottomSheetVariant.menu,
      builder: (BuildContext sheetContext, VoidCallback close) {
        return StarBottomSheetContent(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              StatusChangeSheetBody(onClose: close),
              const Divider(height: 1),
              ListTile(
                leading: const PhosphorIcon(PhosphorIconsBold.users, size: 20),
                title: Text(l10n.profileTabMenuSwitchAccounts),
                trailing: const PhosphorIcon(
                  PhosphorIconsBold.caretRight,
                  size: 20,
                ),
                onTap: () {
                  close();
                  unawaited(AccountSwitcherSheet.show(context));
                },
              ),
              ListTile(
                leading: const PhosphorIcon(PhosphorIconsBold.user, size: 20),
                title: Text(l10n.userSettingsNavProfile),
                onTap: () {
                  close();
                  unawaited(UserSettingsModal.show(context));
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
