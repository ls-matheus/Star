import 'package:star_app/core/observability/star_observability.dart';
import 'package:star_app/shared/markdown/emoji_context_tsv.dart';
import 'package:star_markdown/star_markdown.dart';
import 'package:star_markdown_native/star_markdown_native.dart' as native;
import 'package:markdown/markdown.dart' as md;

int starParserFlagsForFeatures(StarMarkdownFeatures features) {
  var flags = 0;
  if (features.allowSpoilers) {
    flags |= native.StarParserFlags.spoilers;
  }
  if (features.allowHeadings) {
    flags |= native.StarParserFlags.headings;
  }
  if (features.allowLists) {
    flags |= native.StarParserFlags.lists;
  }
  if (features.allowCodeBlocks) {
    flags |= native.StarParserFlags.codeBlocks;
  }
  if (features.allowMaskedLinks) {
    flags |= native.StarParserFlags.maskedLinks;
  }
  if (features.allowCommandMentions) {
    flags |= native.StarParserFlags.commandMentions;
  }
  if (features.allowGuildNavigations) {
    flags |= native.StarParserFlags.guildNavigations;
  }
  if (features.allowUserMentions) {
    flags |= native.StarParserFlags.userMentions;
  }
  if (features.allowRoleMentions) {
    flags |= native.StarParserFlags.roleMentions;
  }
  if (features.allowChannelMentions) {
    flags |= native.StarParserFlags.channelMentions;
  }
  if (features.allowEveryoneMentions) {
    flags |= native.StarParserFlags.everyoneMentions;
  }
  if (features.allowBlockquotes) {
    flags |= native.StarParserFlags.blockquotes;
  }
  if (features.allowMultilineBlockquotes) {
    flags |= native.StarParserFlags.multilineBlockquotes;
  }
  if (features.allowSubtext) {
    flags |= native.StarParserFlags.subtext;
  }
  if (features.allowTables) {
    flags |= native.StarParserFlags.tables;
  }
  if (features.allowAlerts) {
    flags |= native.StarParserFlags.alerts;
  }
  if (features.allowAutolinks) {
    flags |= native.StarParserFlags.autolinks;
  }
  return flags;
}

List<md.Node> parseNativeStarMarkdownAst(
  String data,
  StarMarkdownFeatures features,
) {
  try {
    final nodes = native.parseStarMarkdownBinary(
      data,
      flags: starParserFlagsForFeatures(features),
      emojiContextTsv: _mayContainEmoji(data)
          ? buildStarEmojiContextTsv(data)
          : '',
    );
    return native.starNativeAstToMarkdown(nodes);
  } on Object catch (error, stackTrace) {
    StarObservability.instance.recordError(
      error,
      source: 'native_markdown_parser',
      stackTrace: stackTrace,
      context: 'length=${data.length}',
    );
    return [md.Text(data)];
  }
}

bool _mayContainEmoji(String data) {
  if (data.contains(':')) {
    return true;
  }
  for (final int unit in data.codeUnits) {
    if (unit > 0x7f) {
      return true;
    }
  }
  return false;
}
