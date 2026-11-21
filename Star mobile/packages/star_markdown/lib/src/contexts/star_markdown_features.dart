import 'package:flutter/foundation.dart';
import 'package:star_markdown/src/contexts/star_markdown_context.dart';

@immutable
class StarMarkdownFeatures {
  const StarMarkdownFeatures({
    required this.allowAlerts,
    required this.allowAutolinks,
    required this.allowBlockquotes,
    required this.allowChannelMentions,
    required this.allowCodeBlocks,
    required this.allowCommandMentions,
    required this.allowEveryoneMentions,
    required this.allowGuildNavigations,
    required this.allowHeadings,
    required this.allowJumboEmoji,
    required this.allowLists,
    required this.allowMaskedLinks,
    required this.allowMultilineBlockquotes,
    required this.allowPlainInlineCode,
    required this.allowRoleMentions,
    required this.allowSpoilers,
    required this.allowSubtext,
    required this.allowTables,
    required this.allowUserMentions,
  });

  factory StarMarkdownFeatures.forContext(StarMarkdownContext context) {
    return switch (context) {
      StarMarkdownContext.standardWithJumbo => const StarMarkdownFeatures(
        allowAlerts: true,
        allowAutolinks: true,
        allowBlockquotes: true,
        allowChannelMentions: true,
        allowCodeBlocks: true,
        allowCommandMentions: true,
        allowEveryoneMentions: true,
        allowGuildNavigations: true,
        allowHeadings: true,
        allowJumboEmoji: true,
        allowLists: true,
        allowMaskedLinks: true,
        allowMultilineBlockquotes: true,
        allowPlainInlineCode: false,
        allowRoleMentions: true,
        allowSpoilers: true,
        allowSubtext: true,
        allowTables: true,
        allowUserMentions: true,
      ),
      StarMarkdownContext.restrictedInlineReply =>
        const StarMarkdownFeatures(
          allowAlerts: false,
          allowAutolinks: true,
          allowBlockquotes: false,
          allowChannelMentions: true,
          allowCodeBlocks: true,
          allowCommandMentions: true,
          allowEveryoneMentions: true,
          allowGuildNavigations: true,
          allowHeadings: true,
          allowJumboEmoji: false,
          allowLists: true,
          allowMaskedLinks: true,
          allowMultilineBlockquotes: false,
          allowPlainInlineCode: true,
          allowRoleMentions: true,
          allowSpoilers: true,
          allowSubtext: true,
          allowTables: false,
          allowUserMentions: true,
        ),
      StarMarkdownContext.restrictedChannelTopic =>
        const StarMarkdownFeatures(
          allowAlerts: false,
          allowAutolinks: true,
          allowBlockquotes: false,
          allowChannelMentions: true,
          allowCodeBlocks: true,
          allowCommandMentions: true,
          allowEveryoneMentions: true,
          allowGuildNavigations: true,
          allowHeadings: false,
          allowJumboEmoji: false,
          allowLists: false,
          allowMaskedLinks: true,
          allowMultilineBlockquotes: false,
          allowPlainInlineCode: false,
          allowRoleMentions: true,
          allowSpoilers: true,
          allowSubtext: true,
          allowTables: false,
          allowUserMentions: true,
        ),
      StarMarkdownContext.restrictedUserBio => const StarMarkdownFeatures(
        allowAlerts: false,
        allowAutolinks: true,
        allowBlockquotes: true,
        allowChannelMentions: true,
        allowCodeBlocks: false,
        allowCommandMentions: true,
        allowEveryoneMentions: false,
        allowGuildNavigations: true,
        allowHeadings: false,
        allowJumboEmoji: false,
        allowLists: true,
        allowMaskedLinks: true,
        allowMultilineBlockquotes: true,
        allowPlainInlineCode: false,
        allowRoleMentions: false,
        allowSpoilers: true,
        allowSubtext: false,
        allowTables: false,
        allowUserMentions: true,
      ),
      StarMarkdownContext.restrictedEmbedDescription =>
        const StarMarkdownFeatures(
          allowAlerts: true,
          allowAutolinks: true,
          allowBlockquotes: true,
          allowChannelMentions: true,
          allowCodeBlocks: true,
          allowCommandMentions: true,
          allowEveryoneMentions: true,
          allowGuildNavigations: true,
          allowHeadings: true,
          allowJumboEmoji: false,
          allowLists: true,
          allowMaskedLinks: true,
          allowMultilineBlockquotes: true,
          allowPlainInlineCode: false,
          allowRoleMentions: true,
          allowSpoilers: true,
          allowSubtext: true,
          allowTables: false,
          allowUserMentions: true,
        ),
      StarMarkdownContext.standardWithoutJumbo =>
        const StarMarkdownFeatures(
          allowAlerts: true,
          allowAutolinks: true,
          allowBlockquotes: true,
          allowChannelMentions: true,
          allowCodeBlocks: true,
          allowCommandMentions: true,
          allowEveryoneMentions: true,
          allowGuildNavigations: true,
          allowHeadings: true,
          allowJumboEmoji: false,
          allowLists: true,
          allowMaskedLinks: true,
          allowMultilineBlockquotes: true,
          allowPlainInlineCode: false,
          allowRoleMentions: true,
          allowSpoilers: true,
          allowSubtext: true,
          allowTables: true,
          allowUserMentions: true,
        ),
    };
  }

  final bool allowAlerts;
  final bool allowAutolinks;
  final bool allowBlockquotes;
  final bool allowChannelMentions;
  final bool allowCodeBlocks;
  final bool allowCommandMentions;
  final bool allowEveryoneMentions;
  final bool allowGuildNavigations;
  final bool allowHeadings;
  final bool allowJumboEmoji;
  final bool allowLists;
  final bool allowMaskedLinks;
  final bool allowMultilineBlockquotes;
  final bool allowPlainInlineCode;
  final bool allowRoleMentions;
  final bool allowSpoilers;
  final bool allowSubtext;
  final bool allowTables;
  final bool allowUserMentions;

  bool get isRestrictedInlinePreview =>
      allowPlainInlineCode && !allowJumboEmoji && !allowBlockquotes;

  @override
  bool operator ==(Object other) =>
      other is StarMarkdownFeatures &&
      other.allowAlerts == allowAlerts &&
      other.allowAutolinks == allowAutolinks &&
      other.allowBlockquotes == allowBlockquotes &&
      other.allowChannelMentions == allowChannelMentions &&
      other.allowCodeBlocks == allowCodeBlocks &&
      other.allowCommandMentions == allowCommandMentions &&
      other.allowEveryoneMentions == allowEveryoneMentions &&
      other.allowGuildNavigations == allowGuildNavigations &&
      other.allowHeadings == allowHeadings &&
      other.allowJumboEmoji == allowJumboEmoji &&
      other.allowLists == allowLists &&
      other.allowMaskedLinks == allowMaskedLinks &&
      other.allowMultilineBlockquotes == allowMultilineBlockquotes &&
      other.allowPlainInlineCode == allowPlainInlineCode &&
      other.allowRoleMentions == allowRoleMentions &&
      other.allowSpoilers == allowSpoilers &&
      other.allowSubtext == allowSubtext &&
      other.allowTables == allowTables &&
      other.allowUserMentions == allowUserMentions;

  @override
  int get hashCode => Object.hash(
    allowAlerts,
    allowAutolinks,
    allowBlockquotes,
    allowChannelMentions,
    allowCodeBlocks,
    allowCommandMentions,
    allowEveryoneMentions,
    allowGuildNavigations,
    allowHeadings,
    allowJumboEmoji,
    allowLists,
    allowMaskedLinks,
    allowMultilineBlockquotes,
    allowPlainInlineCode,
    allowRoleMentions,
    allowSpoilers,
    allowSubtext,
    allowTables,
    allowUserMentions,
  );
}
