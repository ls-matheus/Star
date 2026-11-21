import 'package:star_app/features/dm/domain/dm_conversation.dart';
import 'package:star_app/features/dm/presentation/widgets/group_dm_invites_content.dart';
import 'package:star_app/features/ui/ui.dart';
import 'package:star_app/l10n/generated/star_localizations.dart';
import 'package:star_app/material_ui.dart';

class GroupDmInvitesBottomSheet {
  GroupDmInvitesBottomSheet._();

  static Future<void> show(BuildContext context, {required DmConversation dm}) {
    final StarLocalizations l10n = StarLocalizations.of(context);
    return StarBottomSheet.showScrollable<void>(
      context,
      title: l10n.channelDetailsGroupInvites,
      useRootNavigator: true,
      minChildSize: 0.45,
      builder:
          (
            BuildContext sheetContext,
            ScrollController scrollController,
            VoidCallback close,
          ) {
            return GroupDmInvitesContent(
              dm: dm,
              scrollController: scrollController,
            );
          },
    );
  }
}
