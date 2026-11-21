import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:star_app/core/theme/star_theme_extension.dart';
import 'package:star_app/features/channels/utils/navigation/navigate_to_channel_content.dart';
import 'package:star_app/features/dm/domain/dm_conversation.dart';
import 'package:star_app/features/dm/presentation/widgets/group_dm_avatar.dart';
import 'package:star_app/features/ui/ui.dart';
import 'package:star_app/l10n/generated/star_localizations.dart';
import 'package:star_app/material_ui.dart';
import 'package:star_app/shared/utils/snowflake_time.dart';
import 'package:intl/intl.dart';

Future<void> showDuplicateGroupConfirmModal(
  BuildContext context,
  WidgetRef ref, {
  required List<DmConversation> channels,
  required Future<void> Function() onConfirm,
}) {
  final StarLocalizations l10n = StarLocalizations.of(context);
  return StarModal.show<void>(
    context,
    title: l10n.createDmConfirmNewGroup,
    centered: true,
    builder: (BuildContext dialogContext, VoidCallback close) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(
            l10n.createDmDuplicateGroupDescription,
            style: dialogContext.textStyles.bodySmall.copyWith(
              color: dialogContext.colors.textSecondary,
              height: 1.4,
            ),
          ),
          SizedBox(height: dialogContext.layout.s4),
          ...channels.map((DmConversation channel) {
            final String activityLabel = _activityLabel(channel, l10n);
            return Padding(
              padding: EdgeInsets.only(bottom: dialogContext.layout.s2),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    close();
                    unawaited(
                      navigateToDmChannelContent(
                        context: context,
                        ref: ref,
                        channelId: channel.id,
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Row(
                      children: <Widget>[
                        GroupDmAvatar.conversation(channel, size: 40),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                dmConversationDisplayName(l10n, channel),
                                style: dialogContext.textStyles.username
                                    .copyWith(
                                      color: dialogContext.colors.textPrimary,
                                    ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                activityLabel,
                                style: dialogContext.textStyles.bodySmall
                                    .copyWith(
                                      color: dialogContext.colors.textTertiary,
                                    ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),
        ],
      );
    },
    actionsBuilder: (void Function([void]) pop) {
      return <Widget>[
        StarButton.primary(
          label: l10n.createDmCreateNewGroup,
          onPressed: () async {
            await onConfirm();
            pop();
          },
        ),
        const SizedBox(height: 8),
        StarButton.secondary(label: l10n.cancel, onPressed: () => pop()),
      ];
    },
  );
}

String _activityLabel(DmConversation channel, StarLocalizations l10n) {
  final String? lastMessageId = channel.lastMessageId;
  if (lastMessageId == null || lastMessageId.isEmpty) {
    return l10n.createDmNoActivityYet;
  }
  final DateTime time = dateTimeFromSnowflakeAsLocalOrNow(lastMessageId);
  return DateFormat.yMMMd(l10n.localeName).add_jm().format(time);
}
