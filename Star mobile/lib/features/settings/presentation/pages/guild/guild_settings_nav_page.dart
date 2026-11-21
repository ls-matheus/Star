import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:star_app/core/providers/app/account_user_id.dart';
import 'package:star_app/core/providers/instance/instance_runtime_config_provider.dart';
import 'package:star_app/core/router/star_router.dart';
import 'package:star_app/core/theme/star_theme_extension.dart';
import 'package:star_app/features/guilds/domain/guild.dart';
import 'package:star_app/features/guilds/providers/guild_providers.dart';
import 'package:star_app/features/guilds/providers/guild_sync_provider.dart';
import 'package:star_app/features/settings/domain/guild/guild_settings_tab.dart';
import 'package:star_app/features/settings/presentation/delete_community_flow.dart';
import 'package:star_app/features/settings/presentation/widgets/guild/guild_settings_page_shell.dart';
import 'package:star_app/features/settings/presentation/widgets/wide_settings_content_layout.dart';
import 'package:star_app/features/settings/providers/guild/guild_settings_tab_providers.dart';
import 'package:star_app/features/shell/hosted_ui/hosted_ui_background_bleed.dart';
import 'package:star_app/features/shell/hosted_ui/iphone_duo_hosted_ui.dart';
import 'package:star_app/features/ui/bottom_sheet/star_bottom_sheet.dart';
import 'package:star_app/features/ui/settings/star_settings_nav_list.dart';
import 'package:star_app/l10n/generated/star_localizations.dart';
import 'package:star_app/material_ui.dart';
import 'package:star_app/shared/icons/phosphor.dart';
import 'package:go_router/go_router.dart';

class GuildSettingsNavPage extends ConsumerStatefulWidget {
  const GuildSettingsNavPage({required this.guildId, super.key});

  final String guildId;

  @override
  ConsumerState<GuildSettingsNavPage> createState() =>
      _GuildSettingsNavPageState();
}

class _GuildSettingsNavPageState extends ConsumerState<GuildSettingsNavPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      ref
          .read(guildSyncProvider(readAccountUserId(ref)).notifier)
          .syncIfNeeded(widget.guildId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final StarLocalizations l10n = StarLocalizations.of(context);
    final int permissions = ref.watch(
      guildSettingsPermissionsProvider(widget.guildId),
    );
    final Guild? guild = ref.watch(guildByIdProvider(widget.guildId)).value;
    final List<GuildSettingsTab> tabs = visibleGuildSettingsTabsForRef(
      ref: ref,
      permissions: permissions,
      guild: guild,
    );
    final bool canDelete = canDeleteCommunity(
      guild: guild,
      currentUserId: ref.watch(currentUserIdProvider),
      isStockCommunity: ref
          .watch(instanceRuntimeConfigProvider)
          .isStockCommunityGuild(widget.guildId),
    );
    final Color backgroundColor = guildSettingsPageBackgroundColor(context);
    return HostedUiBackgroundBleed(
      color: backgroundColor,
      child: Scaffold(
        backgroundColor: backgroundColor,
        appBar: AppBar(
          backgroundColor: backgroundColor,
          elevation: 0,
          scrolledUnderElevation: 0,
          surfaceTintColor: Colors.transparent,
          automaticallyImplyLeading: false,
          title: Text(l10n.guildSettingsCommunitySettings),
          leading: showsInAppShellBackButton(context)
              ? IconButton(
                  tooltip: l10n.back,
                  icon: const PhosphorIcon(PhosphorIconsBold.arrowLeft),
                  onPressed: () => context.pop(),
                )
              : null,
        ),
        body: StarSettingsNavList(
          padding: settingsScrollPadding(context),
          groups: _buildNavGroups(l10n, tabs, context, widget.guildId, ref),
          footer: canDelete
              ? Padding(
                  padding: EdgeInsets.only(top: context.layout.s2),
                  child: StarMenuGroup(
                    children: <Widget>[
                      StarBottomSheetMenuItem(
                        label: l10n.guildSettingsDeleteCommunity,
                        icon: PhosphorIconsFill.trash,
                        isDanger: true,
                        onTap: () => unawaited(
                          DeleteCommunityFlow.confirmAndDelete(
                            context,
                            ref,
                            guildId: widget.guildId,
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              : null,
        ),
      ),
    );
  }

  List<StarSettingsNavGroup> _buildNavGroups(
    StarLocalizations l10n,
    List<GuildSettingsTab> tabs,
    BuildContext context,
    String guildId,
    WidgetRef ref,
  ) {
    final List<StarSettingsNavGroup> groups = <StarSettingsNavGroup>[];
    String? currentCategory;
    List<StarSettingsNavItem> currentItems = <StarSettingsNavItem>[];
    void flushGroup() {
      if (currentItems.isEmpty) {
        return;
      }
      groups.add(
        StarSettingsNavGroup(label: currentCategory, items: currentItems),
      );
      currentItems = <StarSettingsNavItem>[];
    }

    for (final GuildSettingsTab tab in tabs) {
      final String? category = guildSettingsTabCategoryLabel(l10n, tab);
      if (category != currentCategory) {
        flushGroup();
        currentCategory = category;
      }
      currentItems.add(
        StarSettingsNavItem(
          label: guildSettingsTabTitle(l10n, tab),
          icon: guildSettingsTabIcon(tab),
          onTap: () => context.push(guildSettingsTabPath(guildId, tab)),
        ),
      );
    }
    flushGroup();
    return groups;
  }
}
