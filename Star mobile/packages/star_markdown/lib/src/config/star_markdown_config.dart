import 'package:flutter/widgets.dart';
import 'package:star_markdown/src/utils/ansi_palette.dart';
import 'package:material_ui/material_ui.dart';

enum StarGuildNavigationType { customize, browse, guide, linkedRoles }

StarGuildNavigationType? parseStarGuildNavigationType(String raw) {
  return switch (raw) {
    'customize' => StarGuildNavigationType.customize,
    'browse' => StarGuildNavigationType.browse,
    'guide' => StarGuildNavigationType.guide,
    'linked-roles' => StarGuildNavigationType.linkedRoles,
    _ => null,
  };
}

enum StarAlertType { note, tip, important, warning, caution }

StarAlertType? tryParseStarAlertType(String raw) {
  return switch (raw.toUpperCase()) {
    'NOTE' => StarAlertType.note,
    'TIP' => StarAlertType.tip,
    'IMPORTANT' => StarAlertType.important,
    'WARNING' => StarAlertType.warning,
    'CAUTION' => StarAlertType.caution,
    _ => null,
  };
}

typedef StarUnicodeEmojiUrlBuilder = String? Function(String unicode);
typedef StarCustomEmojiUrlBuilder =
    String Function({
      required String id,
      required bool animated,
      required int size,
    });
typedef StarMentionBuilder =
    Widget Function(BuildContext context, String id, TextStyle style);
typedef StarEveryoneMentionBuilder =
    Widget Function(BuildContext context, String label, TextStyle style);
typedef StarCommandMentionBuilder =
    Widget Function(
      BuildContext context,
      String command,
      String applicationId,
      TextStyle style,
    );
typedef StarGuildNavigationMentionBuilder =
    Widget Function(
      BuildContext context,
      StarGuildNavigationType type,
      String? navigationId,
      TextStyle style,
    );
typedef StarLinkWidgetBuilder =
    Widget? Function(BuildContext context, String href, TextStyle style);
typedef StarLinkTapHandler =
    Future<void> Function(BuildContext context, String href);
typedef StarAlertBuilder =
    Widget Function(
      BuildContext context,
      StarAlertType type,
      Widget body,
      TextStyle baseStyle,
    );
typedef StarSpoilerSyncKeyNormalizer = String? Function(String raw);
typedef StarCodeCopyHandler =
    void Function(BuildContext context, String code);
typedef StarTimestampFormatter =
    String Function(DateTime localDateTime, String style);
typedef StarSelectionContextMenuBuilder =
    Widget Function(
      BuildContext context,
      SelectableRegionState selectableRegionState,
    );
typedef StarEmojiLongPressHandler =
    void Function(
      BuildContext context, {
      required String? emojiId,
      required String name,
      required bool animated,
      required bool isCustom,
    });

class StarSpoilerSyncController extends ChangeNotifier {
  final Set<String> _revealedKeys = <String>{};
  var _isDisposed = false;

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }

  bool isRevealed(Iterable<String> keys) {
    if (_isDisposed) {
      return false;
    }
    return keys.any(_revealedKeys.contains);
  }

  void reveal(Iterable<String> keys) {
    if (_isDisposed) {
      return;
    }
    var changed = false;
    for (final key in keys) {
      if (key.isEmpty) {
        continue;
      }
      changed = _revealedKeys.add(key) || changed;
    }
    if (changed) {
      notifyListeners();
    }
  }
}

class StarMarkdownConfig {
  const StarMarkdownConfig({
    required this.unicodeEmojiUrlBuilder,
    required this.customEmojiUrlBuilder,
    this.unicodeEmojiMatcher,
    this.animateCustomEmoji = true,
    this.linkColor,
    this.blockquoteBorderColor,
    this.blockquoteTextColor,
    this.inlineCodeBackgroundColor,
    this.inlineCodeTextColor,
    this.codeTextStyle,
    this.tableBorderColor,
    this.tableHeaderBackgroundColor,
    this.tableHeaderTextColor,
    this.tableRowOddBackgroundColor,
    this.tableRowEvenBackgroundColor,
    this.tableBorderRadius,
    this.spoilerBackgroundColor,
    this.internalLinkPattern,
    this.userMentionBuilder,
    this.channelMentionBuilder,
    this.roleMentionBuilder,
    this.everyoneMentionBuilder,
    this.commandMentionBuilder,
    this.guildNavigationMentionBuilder,
    this.linkWidgetBuilder,
    this.onTapLink,
    this.alertBuilder,
    this.spoilersInitiallyRevealed = false,
    this.spoilerSyncController,
    this.spoilerSyncKeyNormalizer,
    this.onCopyCode,
    this.timestampFormatter,
    this.selectionContextMenuBuilder,
    this.onEmojiLongPress,
    this.alwaysUnderlineLinks = false,
    this.dimStrikethroughText = true,
    this.ansiPalette,
  });

  final StarUnicodeEmojiUrlBuilder unicodeEmojiUrlBuilder;
  final StarCustomEmojiUrlBuilder customEmojiUrlBuilder;
  final Object? unicodeEmojiMatcher;
  final bool animateCustomEmoji;
  final Color? linkColor;
  final Color? blockquoteBorderColor;
  final Color? blockquoteTextColor;
  final Color? inlineCodeBackgroundColor;
  final Color? inlineCodeTextColor;
  final TextStyle? codeTextStyle;
  final Color? tableBorderColor;
  final Color? tableHeaderBackgroundColor;
  final Color? tableHeaderTextColor;
  final Color? tableRowOddBackgroundColor;
  final Color? tableRowEvenBackgroundColor;
  final BorderRadius? tableBorderRadius;
  final Color? spoilerBackgroundColor;
  final RegExp? internalLinkPattern;
  final StarMentionBuilder? userMentionBuilder;
  final StarMentionBuilder? channelMentionBuilder;
  final StarMentionBuilder? roleMentionBuilder;
  final StarEveryoneMentionBuilder? everyoneMentionBuilder;
  final StarCommandMentionBuilder? commandMentionBuilder;
  final StarGuildNavigationMentionBuilder? guildNavigationMentionBuilder;
  final StarLinkWidgetBuilder? linkWidgetBuilder;
  final StarLinkTapHandler? onTapLink;
  final StarAlertBuilder? alertBuilder;
  final bool spoilersInitiallyRevealed;
  final StarSpoilerSyncController? spoilerSyncController;
  final StarSpoilerSyncKeyNormalizer? spoilerSyncKeyNormalizer;
  final StarCodeCopyHandler? onCopyCode;
  final StarTimestampFormatter? timestampFormatter;
  final StarSelectionContextMenuBuilder? selectionContextMenuBuilder;
  final StarEmojiLongPressHandler? onEmojiLongPress;
  final bool alwaysUnderlineLinks;
  final bool dimStrikethroughText;
  final AnsiPalette? ansiPalette;

  Object get layoutCacheKey => (
    animateCustomEmoji,
    linkColor,
    blockquoteBorderColor,
    blockquoteTextColor,
    inlineCodeBackgroundColor,
    inlineCodeTextColor,
    codeTextStyle,
    tableBorderColor,
    tableHeaderBackgroundColor,
    tableHeaderTextColor,
    tableRowOddBackgroundColor,
    tableRowEvenBackgroundColor,
    tableBorderRadius,
    spoilerBackgroundColor,
    spoilersInitiallyRevealed,
    alwaysUnderlineLinks,
    dimStrikethroughText,
    ansiPalette,
    spoilerSyncController,
    unicodeEmojiMatcher,
    internalLinkPattern,
    selectionContextMenuBuilder,
  );
}
