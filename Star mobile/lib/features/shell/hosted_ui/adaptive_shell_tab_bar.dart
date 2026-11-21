import 'package:adaptive_platform_ui/adaptive_platform_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:star_app/core/badge/app_icon_badge.dart';
import 'package:star_app/core/badge/app_icon_badge_provider.dart';
import 'package:star_app/core/theme/star_theme_extension.dart';
import 'package:star_app/features/settings/providers/view_models/user_settings_view_model.dart';
import 'package:star_app/l10n/generated/star_localizations.dart';
import 'package:star_app/material_ui.dart';
import 'package:star_app/shared/icons/phosphor.dart';

AdaptiveBottomNavigationBar adaptiveShellTabBar({
  required BuildContext context,
  required WidgetRef ref,
  required int selectedIndex,
  required ValueChanged<int> onTap,
}) {
  final StarLocalizations l10n = StarLocalizations.of(context);
  final colors = context.colors;
  final UserSettingsViewState user = ref.watch(userSettingsViewModelProvider);
  final int unreadCount =
      ref.watch(
        appIconBadgeProvider.select((AppIconBadgeValue? badge) => badge?.count),
      ) ??
      0;

  final String? avatarUrl = user.avatarUrl;
  final Object profileIcon = avatarUrl != null && avatarUrl.isNotEmpty
      ? NetworkImage(avatarUrl)
      : PhosphorIconsFill.user;

  return AdaptiveBottomNavigationBar(
    selectedIndex: selectedIndex,
    onTap: onTap,
    selectedItemColor: colors.textChat,
    unselectedItemColor: colors.textPrimaryMuted,
    items: <AdaptiveNavigationDestination>[
      AdaptiveNavigationDestination(
        icon: PhosphorIconsFill.house,
        label: l10n.navHome,
        badgeCount: unreadCount > 0 ? unreadCount : null,
      ),
      AdaptiveNavigationDestination(
        icon: PhosphorIconsFill.bell,
        label: l10n.navNotifications,
      ),
      AdaptiveNavigationDestination(icon: profileIcon, label: l10n.navYou),
    ],
  );
}
