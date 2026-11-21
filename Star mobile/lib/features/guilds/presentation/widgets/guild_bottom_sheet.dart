import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:star_app/core/providers/instance/instance_runtime_config_provider.dart';
import 'package:star_app/core/router/route_names.dart';
import 'package:star_app/core/theme/star_theme_extension.dart';
import 'package:star_app/features/guilds/domain/guild.dart';
import 'package:star_app/features/guilds/presentation/widgets/guild_bottom_sheet_avatar.dart';
import 'package:star_app/features/guilds/presentation/widgets/guild_bottom_sheet_stats.dart';
import 'package:star_app/features/guilds/presentation/widgets/guild_menu_data.dart';
import 'package:star_app/features/settings/providers/preferences/time_format_providers.dart';
import 'package:star_app/features/settings/providers/view_models/user_settings_view_model.dart';
import 'package:star_app/features/ui/ui.dart';
import 'package:star_app/l10n/generated/star_localizations.dart';
import 'package:star_app/material_ui.dart';
import 'package:star_app/shared/providers/input_modality_provider.dart';
import 'package:star_app/shared/utils/clipboard_utils.dart';
import 'package:go_router/go_router.dart';

void dismissGuildBottomSheet(BuildContext context) {
  closeStarSheetOpenedFrom(context, useRootNavigator: true);
}

Future<GuildAction?> showGuildBottomSheet(
  BuildContext context, {
  required Guild guild,
  bool hasUnread = false,
  bool isMuted = false,
  bool isOwner = false,
  int permissions = 0,
  bool? canInvite,
  DateTime? muteEndTime,
  bool hideMutedChannels = false,
  bool developerMode = false,
}) async {
  final StarLocalizations l10n = StarLocalizations.of(context);
  final String locale = Localizations.localeOf(context).toString();
  final ProviderContainer container = ProviderScope.containerOf(context);
  final groups = buildGuildMenuGroups(
    l10n: l10n,
    hasUnread: hasUnread,
    isMuted: isMuted,
    isOwner: isOwner,
    permissions: permissions,
    canInvite: canInvite,
    locale: locale,
    use12Hour: container.read(use12HourTimeFormatProvider),
    muteEndTime: muteEndTime,
    hideMutedChannels: hideMutedChannels,
    developerMode: developerMode,
    isTouchPrimary: container.read(inputModalityProvider),
    canEditCommunityProfile: !container
        .read(userSettingsViewModelProvider)
        .isKnownUnclaimed,
    isStockCommunity: container
        .read(instanceRuntimeConfigProvider)
        .isStockCommunityGuild(guild.id),
    guild: guild,
  );

  final result = await StarBottomSheet.showScrollable<GuildAction>(
    context,
    desktop: const StarDesktopPresentation(
      surface: StarDesktopSurface.menu,
      width: 260,
    ),
    title: guild.name,
    leading: GuildBottomSheetAvatar(guild: guild),
    subtitle: GuildBottomSheetStats(guildId: guild.id, fallbackGuild: guild),
    initialChildSize: StarBottomSheet.scrollableSheetHalfSize,
    useRootNavigator: true,
    builder: (sheetContext, scrollController, close) {
      final layout = sheetContext.layout;
      void pop(GuildAction action) => Navigator.of(sheetContext).pop(action);

      final menuGroups = <Widget>[
        for (final group in groups)
          if (group.isNotEmpty)
            StarMenuGroup(
              children: [
                for (final entry in group)
                  _buildMenuEntry(sheetContext, entry, pop, guild.id),
              ],
            ),
      ];

      return ListView(
        controller: scrollController,
        padding: StarBottomSheet.scrollViewPadding(
          sheetContext,
          padding: EdgeInsets.symmetric(horizontal: layout.s4),
        ),
        children: [StarBottomSheetGroupColumn(children: menuGroups)],
      );
    },
  );

  if (result == GuildAction.copyGuildId && context.mounted) {
    await copyToClipboard(context: context, value: guild.id);
  }

  return result;
}

Widget _buildMenuEntry(
  BuildContext context,
  GuildMenuEntry entry,
  void Function(GuildAction) pop,
  String guildId,
) {
  return switch (entry) {
    GuildMenuAction() => StarBottomSheetMenuItem(
      label: entry.label,
      hint: entry.hint,
      icon: entry.icon,
      isDanger: entry.isDanger,
      onTap: () => pop(entry.action),
    ),
    GuildMenuSubmenu() => StarBottomSheetSubmenuItem(
      label: entry.label,
      hint: entry.hint,
      icon: entry.icon,
      onTap: () => _handleSubmenuTap(context, entry, guildId),
    ),
    GuildMenuCheckbox() => StarBottomSheetCheckboxItem(
      label: entry.label,
      isChecked: entry.isChecked,
      onTap: () => pop(entry.action),
    ),
  };
}

void _handleSubmenuTap(
  BuildContext context,
  GuildMenuSubmenu submenu,
  String guildId,
) {
  switch (submenu.key) {
    case 'communitySettings':
      Navigator.of(context, rootNavigator: true).pop();
      unawaited(context.push(RoutePaths.guildSettingsPath(guildId)));
    default:
      _openSubmenu(context, submenu);
  }
}

void _openSubmenu(BuildContext context, GuildMenuSubmenu submenu) {
  final NavigatorState nav = Navigator.of(context, rootNavigator: true);
  unawaited(
    StarBottomSheet.showScrollable<GuildAction>(
      context,
      title: submenu.label,
      onBack: nav.pop,
      initialChildSize: StarBottomSheet.scrollableSheetHalfSize,
      useRootNavigator: true,
      builder: (sheetContext, scrollController, close) {
        final layout = sheetContext.layout;
        void pop(GuildAction action) => Navigator.of(sheetContext).pop(action);

        return ListView(
          controller: scrollController,
          padding: StarBottomSheet.scrollViewPadding(
            sheetContext,
            padding: EdgeInsets.symmetric(horizontal: layout.s4),
          ),
          children: [
            StarBottomSheetGroupColumn(
              children: [
                StarMenuGroup(
                  children: [
                    for (final entry in submenu.children)
                      if (entry is GuildMenuAction)
                        StarBottomSheetMenuItem(
                          label: entry.label,
                          icon: entry.icon,
                          onTap: () => pop(entry.action),
                        ),
                  ],
                ),
              ],
            ),
          ],
        );
      },
    ).then((result) {
      if (result != null) {
        nav.pop(result);
      }
    }),
  );
}
