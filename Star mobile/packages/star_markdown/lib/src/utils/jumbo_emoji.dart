const kStarMarkdownJumboMaxCount = 30;
const kStarMarkdownEmojiSizeMultiplier = 1.5;

const kStarMarkdownEmojiSizeJumbo = 48.0;
const kStarMarkdownRestrictedInlineEmojiEm = 1.25;

double starMarkdownEmojiSize({
  required double? fontSize,
  required double? height,
  required bool jumbo,
  bool fitToLineHeight = false,
}) {
  if (jumbo) {
    return kStarMarkdownEmojiSizeJumbo;
  }
  final double resolvedFontSize = fontSize ?? 16;
  if (fitToLineHeight) {
    return resolvedFontSize *
        (height ?? kStarMarkdownRestrictedInlineEmojiEm);
  }
  return resolvedFontSize * kStarMarkdownEmojiSizeMultiplier;
}
