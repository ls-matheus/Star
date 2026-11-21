import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:star_app/core/theme/star_theme_extension.dart';
import 'package:star_app/features/channels/domain/channel.dart';
import 'package:star_app/features/channels/domain/channel_settings_tab.dart';
import 'package:star_app/features/channels/presentation/channel_settings/channel_settings_gate.dart';
import 'package:star_app/features/channels/presentation/channel_settings/channel_settings_page_shell.dart';
import 'package:star_app/features/channels/presentation/delete_channel_flow.dart';
import 'package:star_app/features/channels/presentation/widgets/channel_icon.dart';
import 'package:star_app/features/shell/hosted_ui/hosted_ui_background_bleed.dart';
import 'package:star_app/features/shell/hosted_ui/iphone_duo_hosted_ui.dart';
import 'package:star_app/features/ui/bottom_sheet/star_bottom_sheet.dart';
import 'package:star_app/features/ui/settings/star_settings_nav_list.dart';
import 'package:star_app/l10n/generated/star_localizations.dart';
import 'package:star_app/material_ui.dart';
import 'package:star_app/shared/icons/phosphor.dart';
import 'package:go_router/go_router.dart';

class ChannelSettingsNavPage extends ConsumerWidget {
  const ChannelSettingsNavPage({required this.channelId, super.key});

  final String channelId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ChannelSettingsGate(
      channelId: channelId,
      builder:
          (
            BuildContext context,
            WidgetRef ref,
            Channel channel,
            int permissions,
          ) {
            final StarLocalizations l10n = StarLocalizations.of(context);
            final Color backgroundColor = channelSettingsPageBackgroundColor(
              context,
            );
            final List<ChannelSettingsTab> visibleTabs =
                visibleChannelSettingsTabs(
                  channel: channel,
                  permissions: permissions,
                );
            final bool canDelete = canDeleteChannel(permissions: permissions);
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
                  leading: showsInAppShellBackButton(context)
                      ? IconButton(
                          tooltip: l10n.back,
                          icon: const PhosphorIcon(PhosphorIconsBold.arrowLeft),
                          onPressed: () => context.pop(),
                        )
                      : null,
                  centerTitle: true,
                  title: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      ChannelIcon(type: channel.type, channel: channel),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          channel.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                  actions: const <Widget>[SizedBox(width: 48)],
                ),
                body: StarSettingsNavList(
                  padding: EdgeInsets.fromLTRB(
                    context.layout.s4,
                    context.layout.s4,
                    context.layout.s4,
                    context.layout.s4,
                  ),
                  groups: _buildNavGroups(
                    context: context,
                    l10n: l10n,
                    channelId: channelId,
                    visibleTabs: visibleTabs,
                  ),
                  footer: canDelete
                      ? Padding(
                          padding: EdgeInsets.only(top: context.layout.s2),
                          child: StarMenuGroup(
                            children: <Widget>[
                              StarBottomSheetMenuItem(
                                label: channelSettingsDeleteLabel(
                                  l10n,
                                  channel: channel,
                                ),
                                icon: PhosphorIconsFill.trash,
                                isDanger: true,
                                onTap: () => unawaited(
                                  DeleteChannelFlow.confirmAndDelete(
                                    context,
                                    ref,
                                    channel: channel,
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
          },
    );
  }
}

List<StarSettingsNavGroup> _buildNavGroups({
  required BuildContext context,
  required StarLocalizations l10n,
  required String channelId,
  required List<ChannelSettingsTab> visibleTabs,
}) {
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

  for (final ChannelSettingsTab tab in visibleTabs) {
    final String? category = channelSettingsTabCategoryLabel(l10n, tab);
    if (category != currentCategory) {
      flushGroup();
      currentCategory = category;
    }
    currentItems.add(
      StarSettingsNavItem(
        label: channelSettingsTabTitle(l10n, tab),
        icon: channelSettingsTabIcon(tab),
        onTap: () => context.push(channelSettingsTabPath(channelId, tab)),
      ),
    );
  }
  flushGroup();
  return groups;
}
