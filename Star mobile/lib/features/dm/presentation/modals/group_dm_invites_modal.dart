import 'package:star_app/features/dm/domain/dm_conversation.dart';
import 'package:star_app/features/dm/presentation/widgets/group_dm_invites_content.dart';
import 'package:star_app/features/ui/ui.dart';
import 'package:star_app/l10n/generated/star_localizations.dart';
import 'package:star_app/material_ui.dart';

class GroupDmInvitesModal {
  GroupDmInvitesModal._();

  static Future<void> show(BuildContext context, {required DmConversation dm}) {
    final StarLocalizations l10n = StarLocalizations.of(context);
    return StarModal.show<void>(
      context,
      title: l10n.channelDetailsGroupInvites,
      builder: (BuildContext dialogContext, VoidCallback close) {
        return SizedBox(height: 360, child: GroupDmInvitesContent(dm: dm));
      },
    );
  }
}
