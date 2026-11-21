import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:star_app/core/media/star_media_url.dart';
import 'package:star_app/core/theme/star_theme_extension.dart';
import 'package:star_app/features/members/domain/member.dart';
import 'package:star_app/features/settings/domain/guild/guild_audit_log_constants.dart';
import 'package:star_app/features/settings/domain/guild/guild_audit_log_state.dart';
import 'package:star_app/features/settings/providers/guild/guild_audit_log_provider.dart';
import 'package:star_app/features/shell/presentation/responsive_layout.dart';
import 'package:star_app/features/ui/ui.dart';
import 'package:star_app/l10n/generated/star_localizations.dart';
import 'package:star_app/material_ui.dart';
import 'package:star_app/shared/icons/phosphor.dart';
import 'package:star_dart/export.dart';

const String kGuildAuditLogAllUsersFilterValue = '';
const String kGuildAuditLogAllActionsFilterValue = '';

class GuildAuditLogFilterRow extends ConsumerWidget {
  const GuildAuditLogFilterRow({
    required this.guildId,
    required this.state,
    required this.l10n,
    super.key,
  });

  final String guildId;
  final GuildAuditLogState state;
  final StarLocalizations l10n;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final List<StarSelectItem<String>> userItems = <StarSelectItem<String>>[
      StarSelectItem<String>(
        value: kGuildAuditLogAllUsersFilterValue,
        label: l10n.guildSettingsAuditLogFilterAllUsers,
      ),
      ...state.filterMembers.map(
        (Member member) => StarSelectItem<String>(
          value: member.id,
          label: member.displayName,
          leading: StarAvatar.user(
            imageUrl: _resolveFilterAvatarUrl(member),
            fallbackText: member.displayName,
            userId: member.id,
            avatarColor:
                state.filterMemberAvatarColor(member.id) ?? member.avatarColor,
            size: 28,
            showStatus: false,
          ),
        ),
      ),
    ];
    final List<StarSelectItem<String>> actionItems =
        <StarSelectItem<String>>[
          StarSelectItem<String>(
            value: kGuildAuditLogAllActionsFilterValue,
            label: l10n.guildSettingsAuditLogFilterAllActions,
            icon: PhosphorIconsFill.funnelSimple,
          ),
          ...GuildAuditLogConstants.filterableActions.map(
            (AuditLogActionType action) => StarSelectItem<String>(
              value: action.json?.toString() ?? '',
              label: GuildAuditLogConstants.getActionLabel(action, l10n),
              icon: GuildAuditLogConstants.getActionIcon(action),
            ),
          ),
        ];
    final bool isMobile = isMobileLayout(context);
    final Widget userSelect = StarSelect<String>(
      label: l10n.guildSettingsAuditLogFilterUser,
      value: state.selectedUserId ?? kGuildAuditLogAllUsersFilterValue,
      items: userItems,
      scrollableSheet: true,
      stretch: isMobile,
      onChanged: (String value) {
        unawaited(
          ref
              .read(guildAuditLogProvider(guildId).notifier)
              .setUserFilter(value.isEmpty ? null : value),
        );
      },
    );
    final Widget actionSelect = StarSelect<String>(
      label: l10n.guildSettingsAuditLogFilterAction,
      value:
          state.selectedActionType?.json?.toString() ??
          kGuildAuditLogAllActionsFilterValue,
      items: actionItems,
      scrollableSheet: true,
      stretch: isMobile,
      onChanged: (String value) {
        final AuditLogActionType? actionType = value.isEmpty
            ? null
            : AuditLogActionType.fromJson(int.parse(value));
        unawaited(
          ref
              .read(guildAuditLogProvider(guildId).notifier)
              .setActionFilter(actionType),
        );
      },
    );
    if (isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          userSelect,
          SizedBox(height: context.layout.s3),
          actionSelect,
        ],
      );
    }
    return Row(
      children: <Widget>[
        Expanded(child: userSelect),
        SizedBox(width: context.layout.s3),
        Expanded(child: actionSelect),
      ],
    );
  }

  String? _resolveFilterAvatarUrl(Member member) {
    final String? guildAvatarUrl = state.filterMemberAvatarUrl(member.id);
    if (guildAvatarUrl != null) {
      return guildAvatarUrl;
    }
    if (!state.hasResolvedProfiles) {
      return null;
    }
    return StarMediaUrl.userAvatar(userId: member.id, hash: member.avatar);
  }
}
