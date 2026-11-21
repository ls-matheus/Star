import 'package:star_app/core/theme/star_motion_theme.dart';
import 'package:star_app/core/theme/star_theme_extension.dart';
import 'package:star_app/core/zoom/star_app_zoom.dart';
import 'package:star_app/features/chat/domain/favorite_meme.dart';
import 'package:star_app/features/chat/domain/gif_selection.dart';
import 'package:star_app/features/chat/presentation/widgets/pickers/expression_picker.dart';
import 'package:star_app/features/chat/presentation/widgets/pickers/expression_segmented_tabs.dart';
import 'package:star_app/features/chat/providers/pickers/sticker_picker_provider.dart';
import 'package:star_app/features/chat/utils/composer/inline_expression_panel_layout.dart';
import 'package:star_app/features/ui/bottom_sheet/star_bottom_sheet.dart';
import 'package:star_app/features/ui/bottom_sheet/star_sheet_motion.dart';
import 'package:star_app/features/ui/emoji_picker/star_selected_emoji.dart';
import 'package:star_app/l10n/generated/star_localizations.dart';
import 'package:star_app/material_ui.dart';

const Duration kReactionPickerRiseDuration = Duration(milliseconds: 400);
const double kReactionPickerRiseStartFraction = 0.558;
const Curve kReactionPickerRiseSpring = StarSpringCurve(
  stiffness: 870,
  damping: 38.4,
  duration: kReactionPickerRiseDuration,
);

class ReactionPickerRiseCurve extends Curve {
  const ReactionPickerRiseCurve({required this.start});

  final double start;

  @override
  double transformInternal(double t) =>
      start + (1 - start) * kReactionPickerRiseSpring.transform(t);
}

double reactionPickerSheetHeight(BuildContext context) {
  final MediaQueryData view = StarAppZoom.mediaQueryOfView(context);
  return view.size.height - view.viewPadding.top - kExpressionSheetTopInset;
}

AnimationStyle? reactionPickerAnimationStyle(
  BuildContext context, {
  required double sheetHeight,
}) {
  if (context.motion.sheet <= Duration.zero || sheetHeight <= 0) {
    return null;
  }
  final double screenHeight = MediaQuery.sizeOf(context).height;
  return AnimationStyle(
    duration: kReactionPickerRiseDuration,
    curve: ReactionPickerRiseCurve(
      start: (kReactionPickerRiseStartFraction * screenHeight / sheetHeight)
          .clamp(0.0, 1.0),
    ),
    reverseDuration: kStarSheetCloseDuration,
    reverseCurve: Curves.linear,
  );
}

class StarEmojiPickerSheet {
  StarEmojiPickerSheet._();

  static Future<void> show(
    BuildContext context, {
    ValueChanged<StarSelectedEmoji>? onEmojiSelected,
    ValueChanged<StarSelectedGif>? onGifSelected,
    ValueChanged<StickerEntry>? onStickerSelected,
    ValueChanged<FavoriteMemeSelection>? onFavoriteMemeSelected,
    String? title,
    Widget? subtitle,
    List<ExpressionPickerTab> visibleTabs = const [
      ExpressionPickerTab.gifs,
      ExpressionPickerTab.memes,
      ExpressionPickerTab.stickers,
      ExpressionPickerTab.emojis,
    ],
    ExpressionPickerTab initialTab = ExpressionPickerTab.emojis,
    String? channelId,
    String? roleIconGuildId,
  }) {
    final bool emojiOnly =
        visibleTabs.length == 1 &&
        visibleTabs.first == ExpressionPickerTab.emojis;
    final bool searchFollowsHandle =
        visibleTabs.length == 1 && title == null && subtitle == null;
    final double? sheetHeight = emojiOnly
        ? reactionPickerSheetHeight(context)
        : null;
    return StarBottomSheet.showScrollable<void>(
      context,
      title: title,
      subtitle: subtitle,
      bottomGap: false,
      sheetHeight: sheetHeight,
      animationStyle: sheetHeight == null
          ? null
          : reactionPickerAnimationStyle(context, sheetHeight: sheetHeight),
      builder: (context, scrollController, close) {
        return _SheetContent(
          scrollController: scrollController,
          visibleTabs: visibleTabs,
          initialTab: initialTab,
          searchFollowsHandle: searchFollowsHandle,
          onClose: close,
          onEmojiSelected: onEmojiSelected,
          onGifSelected: onGifSelected,
          onStickerSelected: onStickerSelected,
          onFavoriteMemeSelected: onFavoriteMemeSelected,
          channelId: channelId,
          roleIconGuildId: roleIconGuildId,
        );
      },
    );
  }
}

class _SheetContent extends StatefulWidget {
  const _SheetContent({
    required this.scrollController,
    required this.visibleTabs,
    required this.initialTab,
    required this.searchFollowsHandle,
    required this.onClose,
    this.onEmojiSelected,
    this.onGifSelected,
    this.onStickerSelected,
    this.onFavoriteMemeSelected,
    this.channelId,
    this.roleIconGuildId,
  });

  final ScrollController scrollController;
  final List<ExpressionPickerTab> visibleTabs;
  final ExpressionPickerTab initialTab;
  final bool searchFollowsHandle;
  final VoidCallback onClose;
  final ValueChanged<StarSelectedEmoji>? onEmojiSelected;
  final ValueChanged<StarSelectedGif>? onGifSelected;
  final ValueChanged<StickerEntry>? onStickerSelected;
  final ValueChanged<FavoriteMemeSelection>? onFavoriteMemeSelected;
  final String? channelId;
  final String? roleIconGuildId;

  @override
  State<_SheetContent> createState() => _SheetContentState();
}

class _SheetContentState extends State<_SheetContent> {
  late ExpressionPickerTab _selectedTab;

  @override
  void initState() {
    super.initState();
    _selectedTab = widget.initialTab;
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(
      bottom: StarBottomSheet.scrollBottomPaddingOf(context),
    ),
    child: Column(
      children: [
        if (widget.visibleTabs.length > 1) _buildSegmentedTabs(context),
        if (!widget.searchFollowsHandle) const SizedBox(height: 8),
        Expanded(
          child: ExpressionPicker(
            scrollController: widget.scrollController,
            onClose: widget.onClose,
            onEmojiSelect: (name, surrogates) {
              widget.onEmojiSelected?.call(
                StarSelectedEmoji.fromSelection(name, surrogates),
              );
              widget.onClose();
            },
            onGifSelect: widget.onGifSelected,
            onFavoriteMemeSelect: (selection) {
              widget.onFavoriteMemeSelected?.call(selection);
              if (selection.autoSend) {
                widget.onClose();
              }
            },
            onStickerSelect: (sticker) {
              widget.onStickerSelected?.call(sticker);
              widget.onClose();
            },
            onTabChanged: (tab) => setState(() => _selectedTab = tab),
            visibleTabs: widget.visibleTabs,
            initialTab: _selectedTab,
            showTabs: false,
            channelId: widget.channelId,
            roleIconGuildId: widget.roleIconGuildId,
            contentSearchTopPadding: widget.searchFollowsHandle ? 0 : null,
          ),
        ),
      ],
    ),
  );

  Widget _buildSegmentedTabs(BuildContext context) {
    return ExpressionSegmentedTabs(
      tabs: widget.visibleTabs,
      selected: _selectedTab,
      labelOf: (ExpressionPickerTab tab) =>
          expressionTabLabel(tab, StarLocalizations.of(context)),
      onSelected: (ExpressionPickerTab tab) =>
          setState(() => _selectedTab = tab),
    );
  }
}
