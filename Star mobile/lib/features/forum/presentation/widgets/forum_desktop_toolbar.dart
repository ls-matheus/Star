import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:star_app/core/theme/star_theme_extension.dart';
import 'package:star_app/features/channels/domain/channel.dart';
import 'package:star_app/features/forum/domain/forum_channel.dart';
import 'package:star_app/features/forum/presentation/sheets/forum_post_composer_sheet.dart';
import 'package:star_app/features/forum/presentation/widgets/forum_sort_view_panel.dart';
import 'package:star_app/features/forum/presentation/widgets/forum_tag_chip.dart';
import 'package:star_app/features/forum/providers/forum_posts_provider.dart';
import 'package:star_app/features/ui/button/star_button.dart';
import 'package:star_app/features/ui/button/star_button_size.dart';
import 'package:star_app/features/ui/popout/star_popout.dart';
import 'package:star_app/features/ui/tappable/star_gesture_detector.dart';
import 'package:star_app/l10n/generated/star_localizations.dart';
import 'package:star_app/material_ui.dart';
import 'package:star_app/shared/icons/phosphor.dart';
import 'package:star_dart/export.dart' hide ChannelType;

class ForumDesktopToolbar extends ConsumerWidget {
  const ForumDesktopToolbar({
    required this.forum,
    required this.canPost,
    required this.searchController,
    super.key,
  });

  final Channel forum;
  final bool canPost;
  final TextEditingController searchController;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        _ForumSearchCard(
          forum: forum,
          canPost: canPost,
          searchController: searchController,
          onCreatePost: () =>
              unawaited(showForumPostComposerSheet(context, ref, forum: forum)),
        ),
        SizedBox(height: context.layout.s3),
        _ForumFilterRow(forum: forum),
      ],
    );
  }
}

class _ForumSearchCard extends ConsumerWidget {
  const _ForumSearchCard({
    required this.forum,
    required this.canPost,
    required this.searchController,
    required this.onCreatePost,
  });

  final Channel forum;
  final bool canPost;
  final TextEditingController searchController;
  final VoidCallback onCreatePost;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final StarLocalizations l10n = StarLocalizations.of(context);
    final ForumViewState view = ref.watch(forumPostsProvider(forum.id));
    final colors = context.colors;
    final bool unavailable = view.searchUnavailable;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.backgroundSecondary,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colors.backgroundModifierAccent),
      ),
      child: Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(12, 6, 6, 6),
        child: Row(
          children: <Widget>[
            if (unavailable)
              const Expanded(child: SizedBox.shrink())
            else ...<Widget>[
              PhosphorIcon(
                PhosphorIconsBold.magnifyingGlass,
                size: 18,
                color: colors.textTertiary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ListenableBuilder(
                  listenable: searchController,
                  builder: (BuildContext context, Widget? child) {
                    return Row(
                      children: <Widget>[
                        Expanded(
                          child: TextField(
                            controller: searchController,
                            maxLength: forumPostNameMaxLength,
                            style: context.textStyles.bodyMedium.copyWith(
                              color: colors.textPrimary,
                            ),
                            decoration: InputDecoration(
                              counterText: '',
                              isDense: true,
                              hintText: l10n.forumSearchPosts,
                              hintStyle: context.textStyles.bodyMedium.copyWith(
                                color: colors.textTertiary,
                              ),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(
                                vertical: 8,
                              ),
                            ),
                          ),
                        ),
                        if (searchController.text.isNotEmpty)
                          Semantics(
                            button: true,
                            label: StarLocalizations.of(
                              context,
                            ).userSettingsSearchClear,
                            child: StarGestureDetector(
                              onTap: searchController.clear,
                              child: Padding(
                                padding: const EdgeInsets.all(6),
                                child: PhosphorIcon(
                                  PhosphorIconsBold.x,
                                  size: 14,
                                  color: colors.textTertiary,
                                ),
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ),
            ],
            if (canPost) ...<Widget>[
              const SizedBox(width: 8),
              StarButton.primary(
                onPressed: onCreatePost,
                icon: PhosphorIconsBold.plus,
                label: l10n.forumNewPost,
                fitContent: true,
                size: StarButtonSize.small,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ForumFilterRow extends ConsumerWidget {
  const _ForumFilterRow({required this.forum});

  final Channel forum;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final StarLocalizations l10n = StarLocalizations.of(context);
    final ForumViewState view = ref.watch(forumPostsProvider(forum.id));
    final ForumPostsController controller = ref.read(
      forumPostsProvider(forum.id).notifier,
    );
    final List<ForumTagResponse> tags = forumAvailableTags(forum);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        StarPopout(
          anchorBuilder: (BuildContext context, VoidCallback toggle) {
            return StarButton.secondary(
              onPressed: toggle,
              icon: PhosphorIconsBold.sortAscending,
              label: l10n.forumViewOptions,
              fitContent: true,
              size: StarButtonSize.small,
            );
          },
          contentBuilder: (BuildContext context, VoidCallback close) {
            return Material(
              color: context.colors.backgroundFloating,
              elevation: 8,
              borderRadius: BorderRadius.circular(8),
              clipBehavior: Clip.antiAlias,
              child: ConstrainedBox(
                constraints: const BoxConstraints(minWidth: 220),
                child: ForumSortViewPanel(forum: forum),
              ),
            );
          },
        ),
        if (tags.isNotEmpty) ...<Widget>[
          Container(
            width: 1,
            height: 32,
            margin: EdgeInsets.symmetric(horizontal: context.layout.s3),
            color: context.colors.backgroundModifierAccent,
          ),
          Expanded(
            child: Wrap(
              spacing: context.layout.s2,
              runSpacing: context.layout.s2,
              children: <Widget>[
                for (final ForumTagResponse tag in tags)
                  ForumTagChip(
                    tag: tag,
                    selected: view.tagFilter.contains(tag.id),
                    onTap: () => controller.toggleTag(tag.id),
                  ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
