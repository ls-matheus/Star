import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:star_app/core/theme/star_theme_extension.dart';
import 'package:star_app/features/channels/domain/channel.dart';
import 'package:star_app/features/channels/presentation/sheets/mute_duration_sheet.dart';
import 'package:star_app/features/channels/providers/channel_notification_menu_provider.dart';
import 'package:star_app/features/guilds/data/guild_user_settings_repository.dart';
import 'package:star_app/features/shell/presentation/responsive_layout.dart';
import 'package:star_app/features/ui/ui.dart';
import 'package:star_app/l10n/generated/star_localizations.dart';
import 'package:star_app/material_ui.dart';
import 'package:star_app/shared/icons/phosphor.dart';
import 'package:star_dart/export.dart' hide ChannelType;

enum ChannelNotificationMenuLayout { actionMenu, bottomSheet }

class ChannelNotificationMenuContent extends ConsumerWidget {
  const ChannelNotificationMenuContent({
    required this.channel,
    required this.onClose,
    this.layout = ChannelNotificationMenuLayout.bottomSheet,
    super.key,
  });

  final Channel channel;
  final VoidCallback onClose;
  final ChannelNotificationMenuLayout layout;

  bool get _isActionMenu => layout == ChannelNotificationMenuLayout.actionMenu;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final StarLocalizations l10n = StarLocalizations.of(context);
    final AsyncValue<ChannelNotificationMenuState> menuStateAsync = ref.watch(
      channelNotificationMenuStateProvider(channel),
    );

    return menuStateAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.all(16),
        child: SizedBox(width: 24, height: 24, child: StarLoadingSpinner()),
      ),
      error: (_, _) => const SizedBox.shrink(),
      data: (ChannelNotificationMenuState menuState) {
        return _isActionMenu
            ? _buildActionMenu(context, ref, l10n, menuState)
            : _buildBottomSheetMenu(context, ref, l10n, menuState);
      },
    );
  }

  Widget _buildActionMenu(
    BuildContext context,
    WidgetRef ref,
    StarLocalizations l10n,
    ChannelNotificationMenuState menuState,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        ..._muteItems(context, ref, l10n, menuState),
        const StarMenuDivider(),
        ..._defaultItems(context, ref, l10n, menuState),
        const StarMenuDivider(),
        ..._levelItems(context, ref, l10n, menuState),
      ],
    );
  }

  Widget _buildBottomSheetMenu(
    BuildContext context,
    WidgetRef ref,
    StarLocalizations l10n,
    ChannelNotificationMenuState menuState,
  ) {
    return StarBottomSheetContent(
      scrollable: false,
      padding: EdgeInsets.fromLTRB(
        context.layout.pageGutter,
        4,
        context.layout.pageGutter,
        0,
      ),
      child: StarBottomSheetGroupColumn(
        children: <Widget>[
          StarMenuGroup(children: _muteItems(context, ref, l10n, menuState)),
          StarMenuGroup(
            children: _defaultItems(context, ref, l10n, menuState),
          ),
          StarMenuGroup(children: _levelItems(context, ref, l10n, menuState)),
        ],
      ),
    );
  }

  List<Widget> _muteItems(
    BuildContext context,
    WidgetRef ref,
    StarLocalizations l10n,
    ChannelNotificationMenuState menuState,
  ) {
    final String? mutedHint = formatMutedHintText(menuState.muteConfig, l10n);

    if (menuState.isMuted) {
      if (_isActionMenu) {
        return <Widget>[
          StarMenuItem(
            label: l10n.notificationUnmuteChannel,
            hint: mutedHint,
            trailingIcon: PhosphorIconsFill.bellSlash,
            onPressed: () {
              onClose();
              unawaited(_unmute(context, ref));
            },
          ),
        ];
      }
      return <Widget>[
        StarBottomSheetMenuItem(
          label: l10n.notificationUnmuteChannel,
          hint: mutedHint,
          icon: PhosphorIconsFill.bellSlash,
          onTap: () {
            onClose();
            unawaited(_unmute(context, ref));
          },
        ),
      ];
    }

    if (_isActionMenu) {
      return <Widget>[
        StarMenuSubmenuItem(
          label: l10n.notificationMuteChannel,
          onPressed: () => unawaited(_openMuteSheet(context, ref)),
        ),
      ];
    }
    return <Widget>[
      StarBottomSheetSubmenuItem(
        label: l10n.notificationMuteChannel,
        onTap: () => unawaited(_openMuteSheet(context, ref)),
      ),
    ];
  }

  List<Widget> _defaultItems(
    BuildContext context,
    WidgetRef ref,
    StarLocalizations l10n,
    ChannelNotificationMenuState menuState,
  ) {
    final String defaultLabel = menuState.hasCategory
        ? l10n.notificationUseCategoryDefault
        : l10n.notificationUseCommunityDefault;
    final String defaultHint = channelNotificationLevelLabel(
      l10n,
      menuState.effectiveDefault,
    );
    return <Widget>[
      _radioItem(
        label: defaultLabel,
        hint: defaultHint,
        isSelected: menuState.selected == UserNotificationSettings.inherit,
        onSelect: () => _setNotificationLevel(
          context,
          ref,
          UserNotificationSettings.inherit,
        ),
      ),
    ];
  }

  List<Widget> _levelItems(
    BuildContext context,
    WidgetRef ref,
    StarLocalizations l10n,
    ChannelNotificationMenuState menuState,
  ) {
    final List<({UserNotificationSettings value, String label})> options =
        <({UserNotificationSettings value, String label})>[
          (
            value: UserNotificationSettings.allMessages,
            label: l10n.notificationAllMessages,
          ),
          (
            value: UserNotificationSettings.onlyMentions,
            label: l10n.notificationOnlyAtMentions,
          ),
          (
            value: UserNotificationSettings.noMessages,
            label: l10n.notificationNothing,
          ),
        ];

    return options
        .map(
          (({UserNotificationSettings value, String label}) option) =>
              _radioItem(
                label: option.label,
                isSelected: menuState.selected == option.value,
                onSelect: () =>
                    _setNotificationLevel(context, ref, option.value),
              ),
        )
        .toList();
  }

  Widget _radioItem({
    required String label,
    required bool isSelected,
    required Future<void> Function() onSelect,
    String? hint,
  }) {
    if (_isActionMenu) {
      return StarMenuRadioItem(
        label: label,
        hint: hint,
        isSelected: isSelected,
        onPressed: () {
          onClose();
          unawaited(onSelect());
        },
      );
    }
    return StarBottomSheetMenuRadioItem(
      label: label,
      hint: hint,
      isSelected: isSelected,
      onTap: () {
        onClose();
        unawaited(onSelect());
      },
    );
  }

  Future<void> _setNotificationLevel(
    BuildContext context,
    WidgetRef ref,
    UserNotificationSettings setting,
  ) async {
    await ref
        .read(guildUserSettingsRepositoryProvider)
        .updateChannelOverride(
          guildId: channel.guildId,
          channelId: channel.id,
          messageNotifications: setting,
        );
    if (context.mounted) {
      ref
          .read(toastProvider.notifier)
          .show(
            StarToast(
              message: StarLocalizations.of(
                context,
              ).channelDetailsNotificationSettingsUpdated,
              variant: StarToastVariant.success,
            ),
          );
    }
  }

  Future<void> _unmute(BuildContext context, WidgetRef ref) async {
    final StarLocalizations l10n = StarLocalizations.of(context);
    await ref
        .read(guildUserSettingsRepositoryProvider)
        .updateChannelOverride(
          guildId: channel.guildId,
          channelId: channel.id,
          muted: false,
        );
    if (context.mounted) {
      ref
          .read(toastProvider.notifier)
          .show(
            StarToast(
              message: l10n.channelDetailsUnmutedChannel,
              variant: StarToastVariant.success,
            ),
          );
    }
  }

  Future<void> _openMuteSheet(BuildContext context, WidgetRef ref) async {
    final StarLocalizations l10n = StarLocalizations.of(context);
    final MuteSelection? selection = await showMuteDurationSheet(
      context,
      muteTitle: l10n.notificationMuteChannel,
      useRootNavigator: isMobileLayout(context),
    );
    if (selection == null) {
      return;
    }
    onClose();
    await ref
        .read(guildUserSettingsRepositoryProvider)
        .updateChannelOverride(
          guildId: channel.guildId,
          channelId: channel.id,
          muted: true,
          durationSeconds: selection.durationSeconds,
        );
    ref
        .read(toastProvider.notifier)
        .show(
          StarToast(
            message: l10n.channelDetailsMutedChannel,
            variant: StarToastVariant.success,
          ),
        );
  }
}
