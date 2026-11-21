import 'package:star_app/features/bookmarks/presentation/widgets/saved_messages_body.dart';
import 'package:star_app/features/ui/bottom_sheet/star_bottom_sheet.dart';
import 'package:star_app/l10n/generated/star_localizations.dart';
import 'package:star_app/material_ui.dart';

class BookmarksSheet {
  BookmarksSheet._();

  static Future<void> show(BuildContext context) {
    final StarLocalizations l10n = StarLocalizations.of(context);
    return StarBottomSheet.showScrollable<void>(
      context,
      title: l10n.quickSwitcherBookmarksLabel,
      useRootNavigator: true,
      minChildSize: 0.5,
      builder:
          (
            BuildContext _,
            ScrollController scrollController,
            VoidCallback close,
          ) {
            return SavedMessagesBody(
              scrollController: scrollController,
              padding: EdgeInsets.zero,
              onClose: close,
            );
          },
    );
  }
}
