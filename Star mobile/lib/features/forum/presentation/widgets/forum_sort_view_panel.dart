import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:star_app/core/theme/star_theme_extension.dart';
import 'package:star_app/features/channels/domain/channel.dart';
import 'package:star_app/features/forum/domain/forum_channel.dart';
import 'package:star_app/features/forum/providers/forum_posts_provider.dart';
import 'package:star_app/features/ui/bottom_sheet/star_bottom_sheet.dart';
import 'package:star_app/l10n/generated/star_localizations.dart';
import 'package:star_app/material_ui.dart';

class ForumSortViewPanel extends ConsumerWidget {
  const ForumSortViewPanel({
    required this.forum,
    this.forSheet = false,
    super.key,
  });

  final Channel forum;
  final bool forSheet;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final StarLocalizations l10n = StarLocalizations.of(context);
    final ForumViewState view = ref.watch(forumPostsProvider(forum.id));
    final ForumPostsController controller = ref.read(
      forumPostsProvider(forum.id).notifier,
    );
    final ForumSortOrder sortOrder = view.sortOrder(forum);
    final ForumLayout layout = view.layout(forum);
    final List<Widget> groups = <Widget>[
      StarMenuGroup(
        children: <Widget>[
          StarBottomSheetMenuRadioItem(
            label: l10n.forumSortLatestActivity,
            isSelected: sortOrder == ForumSortOrder.latestActivity,
            onTap: () => controller.setSortOrder(ForumSortOrder.latestActivity),
          ),
          StarBottomSheetMenuRadioItem(
            label: l10n.forumSortCreationTime,
            isSelected: sortOrder == ForumSortOrder.creationTime,
            onTap: () => controller.setSortOrder(ForumSortOrder.creationTime),
          ),
        ],
      ),
      if (!isMediaChannel(forum))
        StarMenuGroup(
          children: <Widget>[
            StarBottomSheetMenuRadioItem(
              label: l10n.forumLayoutList,
              isSelected: layout == ForumLayout.list,
              onTap: () => controller.setLayout(ForumLayout.list),
            ),
            StarBottomSheetMenuRadioItem(
              label: l10n.forumLayoutGallery,
              isSelected: layout == ForumLayout.gallery,
              onTap: () => controller.setLayout(ForumLayout.gallery),
            ),
          ],
        ),
    ];

    if (forSheet) {
      return StarBottomSheetGroupColumn(children: groups);
    }

    return Padding(
      padding: EdgeInsets.symmetric(vertical: context.layout.s2),
      child: StarBottomSheetGroupColumn(children: groups),
    );
  }
}
