import 'package:flutter/foundation.dart';

@immutable
class StarSelectedEmoji {
  const StarSelectedEmoji({
    required this.name,
    required this.surrogates,
    this.emojiId,
    this.animated = false,
  });

  factory StarSelectedEmoji.fromSelection(String name, String surrogates) {
    final customEmojiMatch = RegExp(
      r'^<(a?):([^:>]+):(\d+)>$',
    ).firstMatch(surrogates);

    if (customEmojiMatch != null) {
      return StarSelectedEmoji(
        name: name,
        surrogates: surrogates,
        emojiId: customEmojiMatch.group(3),
        animated: customEmojiMatch.group(1) == 'a',
      );
    }

    return StarSelectedEmoji(name: name, surrogates: surrogates);
  }

  final String name;
  final String surrogates;
  final String? emojiId;
  final bool animated;

  bool get isCustom => emojiId != null;
}
