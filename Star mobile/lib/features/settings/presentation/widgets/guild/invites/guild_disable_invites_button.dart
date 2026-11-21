import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:star_app/core/instance/instance_config_snapshot.dart';
import 'package:star_app/core/permissions/permission.dart';
import 'package:star_app/core/providers/instance/active_instance_provider.dart';
import 'package:star_app/core/theme/star_theme_extension.dart';
import 'package:star_app/features/guilds/domain/guild.dart';
import 'package:star_app/features/guilds/providers/guild_providers.dart';
import 'package:star_app/features/guilds/utils/guild_features.dart';
import 'package:star_app/features/settings/providers/guild/guild_invites_provider.dart';
import 'package:star_app/features/settings/providers/guild/guild_settings_tab_providers.dart';
import 'package:star_app/features/ui/button/star_button.dart';
import 'package:star_app/features/ui/button/star_button_size.dart';
import 'package:star_app/features/ui/modal/star_modal.dart';
import 'package:star_app/l10n/generated/star_localizations.dart';
import 'package:star_app/material_ui.dart';

class GuildDisableInvitesButton extends ConsumerWidget {
  const GuildDisableInvitesButton({
    required this.guildId,
    this.embedded = false,
    super.key,
  });

  final String guildId;
  final bool embedded;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final StarLocalizations l10n = StarLocalizations.of(context);
    final int permissions = ref.watch(
      guildSettingsPermissionsProvider(guildId),
    );
    if (!hasPermission(permissions, Permission.manageGuild)) {
      return const SizedBox.shrink();
    }
    final Guild? guild = ref.watch(guildByIdProvider(guildId)).value;
    if (guild == null) {
      return const SizedBox.shrink();
    }
    final bool invitesDisabled = hasGuildFeature(
      guild.features,
      GuildFeatures.invitesDisabled,
    );
    final bool isRaidDetected = hasGuildFeature(
      guild.features,
      GuildFeatures.raidDetected,
    );
    final InstanceConfigSnapshot instance = ref.watch(activeInstanceProvider);
    final String productName = instance.productName;
    final Widget content = Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        if (invitesDisabled)
          StarButton.dangerPrimary(
            label: l10n.guildSettingsInvitesEnableInvites,
            size: StarButtonSize.small,
            fitContent: true,
            onPressed: () => unawaited(
              _confirmToggle(
                context,
                ref,
                l10n: l10n,
                invitesDisabled: invitesDisabled,
                features: guild.features,
              ),
            ),
          )
        else
          StarButton.secondary(
            label: l10n.guildSettingsInvitesPauseInvites,
            size: StarButtonSize.small,
            fitContent: true,
            onPressed: () => unawaited(
              _confirmToggle(
                context,
                ref,
                l10n: l10n,
                invitesDisabled: invitesDisabled,
                features: guild.features,
              ),
            ),
          ),
        if (invitesDisabled) ...<Widget>[
          SizedBox(width: context.layout.s2),
          Flexible(
            child: Text(
              isRaidDetected
                  ? l10n.guildSettingsInvitesPausedBecauseRaid(productName)
                  : l10n.guildSettingsInvitesPausedForCommunity,
              style: context.textStyles.bodyMedium.copyWith(
                color: context.colors.textPrimaryMuted,
              ),
            ),
          ),
        ],
      ],
    );
    if (embedded) {
      return content;
    }
    return Padding(
      padding: EdgeInsets.fromLTRB(
        context.layout.s4,
        0,
        context.layout.s4,
        context.layout.s4,
      ),
      child: content,
    );
  }

  Future<void> _confirmToggle(
    BuildContext context,
    WidgetRef ref, {
    required StarLocalizations l10n,
    required bool invitesDisabled,
    required List<String> features,
  }) async {
    await StarConfirmModal.show(
      context,
      title: invitesDisabled
          ? l10n.guildSettingsInvitesEnableForCommunityTitle
          : l10n.guildSettingsInvitesPauseForCommunityTitle,
      description: invitesDisabled
          ? l10n.guildSettingsInvitesEnableConfirmDescription
          : l10n.guildSettingsInvitesPauseConfirmDescription,
      confirmLabel: invitesDisabled
          ? l10n.enable
          : l10n.guildSettingsInvitesPause,
      isDanger: !invitesDisabled,
      onConfirm: () => unawaited(
        ref
            .read(guildInvitesProvider(guildId).notifier)
            .toggleInvitesDisabled(
              currentFeatures: features,
              disableInvites: !invitesDisabled,
            ),
      ),
    );
  }
}
