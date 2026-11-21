import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:star_app/core/media/star_media_url.dart';
import 'package:star_app/core/providers/instance/instance_runtime_config_provider.dart';
import 'package:star_app/core/theme/star_theme_extension.dart';
import 'package:star_app/features/settings/domain/guild/guild_ban_entry.dart';
import 'package:star_app/features/settings/utils/guild/guild_bans_utils.dart';
import 'package:star_app/features/ui/ui.dart';
import 'package:star_app/l10n/generated/star_localizations.dart';
import 'package:star_app/material_ui.dart';
import 'package:star_app/shared/icons/phosphor.dart';
import 'package:star_app/shared/utils/clipboard_utils.dart';
import 'package:star_app/shared/utils/display_name.dart';

class GuildBanActionsSheet {
  GuildBanActionsSheet._();

  static Future<void> show(
    BuildContext context,
    WidgetRef ref, {
    required GuildBanEntry entry,
    required VoidCallback onViewDetails,
    required VoidCallback onRevokeBan,
  }) {
    final StarLocalizations l10n = StarLocalizations.of(context);
    return StarBottomSheet.show<void>(
      context,
      variant: StarBottomSheetVariant.menu,
      useRootNavigator: true,
      builder: (BuildContext sheetContext, VoidCallback close) {
        final layout = sheetContext.layout;
        return StarBottomSheetContent(
          scrollable: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              _GuildBanActionsHeader(entry: entry),
              SizedBox(height: layout.s3),
              StarBottomSheetGroupColumn(
                children: <Widget>[
                  StarMenuGroup(
                    children: <Widget>[
                      StarBottomSheetMenuItem(
                        label: l10n.guildSettingsBanViewDetails,
                        icon: PhosphorIconsBold.eye,
                        onTap: () {
                          close();
                          onViewDetails();
                        },
                      ),
                    ],
                  ),
                  StarMenuGroup(
                    children: <Widget>[
                      StarBottomSheetMenuItem(
                        label: l10n.userProfileCopyUserId,
                        icon: PhosphorIconsBold.identificationCard,
                        onTap: () async {
                          await copyToClipboard(
                            context: sheetContext,
                            value: entry.userId,
                            message: l10n.dmUserIdCopied,
                          );
                          close();
                        },
                      ),
                    ],
                  ),
                  StarMenuGroup(
                    children: <Widget>[
                      StarBottomSheetMenuItem(
                        label: l10n.guildSettingsRevokeBanTitle,
                        icon: PhosphorIconsBold.prohibit,
                        isDanger: true,
                        onTap: () {
                          close();
                          onRevokeBan();
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _GuildBanActionsHeader extends ConsumerWidget {
  const _GuildBanActionsHeader({required this.entry});

  final GuildBanEntry entry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = entry.ban.user;
    final String displayName = resolveDisplayName(
      username: user.username,
      globalName: user.globalName,
    );
    final String tag = GuildBansUtils.buildUserTag(
      user,
      uniqueUsernames: ref.watch(uniqueUsernamesProvider),
    );
    final layout = context.layout;
    final colors = context.colors;
    final textStyles = context.textStyles;
    return Row(
      children: <Widget>[
        StarAvatar.user(
          fallbackText: displayName,
          userId: user.id,
          imageUrl: StarMediaUrl.userAvatar(
            userId: user.id,
            hash: user.avatar,
          ),
          avatarColor: user.avatarColor,
          showStatus: false,
          size: 48,
        ),
        SizedBox(width: layout.s3),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                displayName,
                style: textStyles.heading.copyWith(
                  fontSize: 16,
                  color: colors.textChat,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                tag,
                style: textStyles.bodySmall.copyWith(
                  color: colors.textPrimaryMuted,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
