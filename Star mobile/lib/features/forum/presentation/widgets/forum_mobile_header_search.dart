import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:star_app/core/platform/star_platform.dart';
import 'package:star_app/core/theme/star_theme_extension.dart';
import 'package:star_app/features/forum/domain/forum_channel.dart';
import 'package:star_app/features/forum/providers/forum_header_search_provider.dart';
import 'package:star_app/features/forum/providers/forum_posts_provider.dart';
import 'package:star_app/features/ui/tappable/star_gesture_detector.dart';
import 'package:star_app/l10n/generated/star_localizations.dart';
import 'package:star_app/material_ui.dart';
import 'package:star_app/shared/icons/phosphor.dart';

class ForumMobileHeaderSearch extends ConsumerStatefulWidget {
  const ForumMobileHeaderSearch({required this.channelId, super.key});

  final String channelId;

  @override
  ConsumerState<ForumMobileHeaderSearch> createState() =>
      _ForumMobileHeaderSearchState();
}

class _ForumMobileHeaderSearchState
    extends ConsumerState<ForumMobileHeaderSearch> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: ref.read(forumPostsProvider(widget.channelId)).query,
    );
    _focusNode = FocusNode();
    _controller.addListener(_onQueryChanged);
  }

  void _onQueryChanged() {
    final String query = _controller.text;
    if (query != ref.read(forumPostsProvider(widget.channelId)).query) {
      ref.read(forumPostsProvider(widget.channelId).notifier).setQuery(query);
    }
  }

  @override
  void didUpdateWidget(ForumMobileHeaderSearch oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.channelId != widget.channelId) {
      _controller.text = ref.read(forumPostsProvider(widget.channelId)).query;
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onQueryChanged);
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _close() {
    _focusNode.unfocus();
    ref.read(forumHeaderSearchProvider(widget.channelId).notifier).collapse();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(forumHeaderSearchProvider(widget.channelId), (
      ForumHeaderSearchState? previous,
      ForumHeaderSearchState next,
    ) {
      if (next.expanded && previous?.expanded != true) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _focusNode.requestFocus();
          }
        });
      }
    });
    final StarLocalizations l10n = StarLocalizations.of(context);
    final bool unavailable = ref
        .watch(forumPostsProvider(widget.channelId))
        .searchUnavailable;
    final colors = context.colors;
    if (unavailable) {
      return Align(
        alignment: AlignmentDirectional.centerStart,
        child: Text(
          l10n.forumSearchPosts,
          style: context.textStyles.channelName,
        ),
      );
    }
    return TextField(
      controller: _controller,
      focusNode: _focusNode,
      maxLength: forumPostNameMaxLength,
      textInputAction: TextInputAction.search,
      style: context.textStyles.inputText.copyWith(color: colors.textPrimary),
      decoration: InputDecoration(
        counterText: '',
        isDense: true,
        hintText: l10n.forumSearchPosts,
        hintStyle: context.textStyles.inputText.copyWith(
          color: colors.textTertiary,
        ),
        prefixIcon: Padding(
          padding: const EdgeInsetsDirectional.only(start: 4),
          child: PhosphorIcon(
            PhosphorIconsBold.magnifyingGlass,
            size: 18,
            color: colors.textTertiary,
          ),
        ),
        prefixIconConstraints: const BoxConstraints(
          minWidth: 32,
          minHeight: 32,
        ),
        suffixIcon: Semantics(
          button: true,
          label: StarLocalizations.of(context).uiClose,
          child: StarGestureDetector(
            onTap: _close,
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: PhosphorIcon(
                PhosphorIconsBold.x,
                size: 16,
                color: colors.textTertiary,
              ),
            ),
          ),
        ),
        suffixIconConstraints: const BoxConstraints(
          minWidth: 36,
          minHeight: 36,
        ),
        filled: true,
        fillColor: colors.backgroundSecondary,
        contentPadding: const EdgeInsets.symmetric(vertical: 8),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: colors.backgroundModifierAccent),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: colors.backgroundModifierAccent),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: isStarMobileOs
                ? colors.backgroundModifierAccent
                : colors.backgroundModifierAccentFocus,
          ),
        ),
      ),
    );
  }
}
