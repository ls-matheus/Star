import 'package:star_app/features/dm/domain/dm_conversation.dart';
import 'package:star_app/features/dm/presentation/widgets/edit_group_dm_content.dart';
import 'package:star_app/features/ui/ui.dart';
import 'package:star_app/l10n/generated/star_localizations.dart';
import 'package:star_app/material_ui.dart';

class EditGroupDmBottomSheet {
  EditGroupDmBottomSheet._();

  static Future<void> show(BuildContext context, {required DmConversation dm}) {
    final StarLocalizations l10n = StarLocalizations.of(context);
    return StarBottomSheet.showScrollable<void>(
      context,
      title: l10n.groupDmEditTitle,
      useRootNavigator: true,
      builder:
          (
            BuildContext sheetContext,
            ScrollController scrollController,
            VoidCallback close,
          ) {
            return EditGroupDmContent(
              dm: dm,
              onSaved: close,
              scrollController: scrollController,
            );
          },
    );
  }
}
