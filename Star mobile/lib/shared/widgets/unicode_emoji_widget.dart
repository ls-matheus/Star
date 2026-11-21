import 'package:flutter/widgets.dart';
import 'package:star_app/shared/utils/emoji/emoji_utils.dart';
import 'package:star_markdown/star_markdown.dart';

class UnicodeEmojiWidget extends StatelessWidget {
  const UnicodeEmojiWidget({
    required this.emoji,
    required this.size,
    super.key,
  });

  final String emoji;
  final double size;

  @override
  Widget build(BuildContext context) {
    final unicode = resolveUnicodeEmoji(emoji);
    final url = getTwemojiUrl(unicode);
    final fallback = SystemEmojiFallback(emoji: unicode, size: size);
    if (url == null) {
      return fallback;
    }
    return CachedEmojiAssetImage(url: url, size: size, fallback: fallback);
  }
}
