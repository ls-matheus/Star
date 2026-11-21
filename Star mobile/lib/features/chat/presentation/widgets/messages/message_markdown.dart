import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:star_app/core/theme/star_theme_extension.dart';
import 'package:star_app/features/chat/domain/message.dart';
import 'package:star_app/features/chat/providers/pickers/emoji_picker_provider.dart';
import 'package:star_app/features/chat/utils/messages/markdown_timestamp_format.dart';
import 'package:star_app/l10n/generated/star_localizations.dart';
import 'package:star_app/material_ui.dart';
import 'package:star_app/shared/markdown/star_markdown_adapter.dart';
import 'package:star_app/shared/markdown/message_markdown_settings.dart';
import 'package:star_app/shared/markdown/native_markdown_parser.dart';
import 'package:star_markdown/star_markdown.dart';

class MessageMarkdown extends ConsumerWidget {
  const MessageMarkdown({
    required this.data,
    this.baseStyle,
    this.selectable = false,
    this.channelId,
    this.guildId,
    this.messageId,
    this.mentionChannels = const [],
    this.markdownContext = StarMarkdownContext.standardWithJumbo,
    this.revealSpoilers = false,
    this.spoilerSyncController,
    this.maxLines,
    this.overflow,
    this.trailingInlineWidget,
    super.key,
  });

  final String data;
  final TextStyle? baseStyle;
  final bool selectable;
  final String? channelId;
  final String? guildId;
  final String? messageId;
  final List<MessageChannelMention> mentionChannels;
  final StarMarkdownContext markdownContext;
  final bool revealSpoilers;
  final StarSpoilerSyncController? spoilerSyncController;
  final int? maxLines;
  final TextOverflow? overflow;
  final Widget? trailingInlineWidget;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(emojiRegistryLoadedProvider);
    final MessageMarkdownSettings settings =
        MessageMarkdownSettingsScope.maybeOf(context) ??
        MessageMarkdownSettings.watch(ref, context);
    final StarLocalizations l10n = StarLocalizations.of(context);
    return StarBoundedTextClip(
      child: MessageMarkdownBinding(
        channelId: channelId,
        guildId: guildId,
        mentionChannels: mentionChannels,
        child: StarMarkdown(
          data: data,
          parseCacheKey: messageId,
          config: createStarMarkdownConfig(
            context: context,
            revealSpoilers: revealSpoilers,
            spoilerSyncController: spoilerSyncController,
            alwaysUnderlineLinks: settings.alwaysUnderlineLinks,
            dimStrikethroughText: settings.dimStrikethroughText,
            animateCustomEmoji: settings.animateCustomEmoji,
            selectionContextMenuBuilder: selectable
                ? settings.selectionContextMenuBuilder ??
                      selectionMenuBuilderFor(settings.searchEngines)
                : null,
            timestampFormatter: (DateTime localDateTime, String style) {
              return formatMarkdownTimestamp(
                localDateTime,
                style,
                l10n,
                use12Hour: settings.use12Hour,
              );
            },
          ),
          baseStyle: baseStyle ?? context.textStyles.messageText,
          selectable: selectable,
          context: markdownContext,
          maxLines: maxLines,
          overflow: overflow,
          trailingInlineWidget: trailingInlineWidget,
          astParser: parseNativeStarMarkdownAst,
        ),
      ),
    );
  }
}
