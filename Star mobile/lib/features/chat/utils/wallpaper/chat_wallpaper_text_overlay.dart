import 'package:star_app/core/theme/star_color_theme.dart';
import 'package:star_app/core/theme/star_text_theme.dart';

StarColorTheme overlayChatWallpaperColors({
  required StarColorTheme current,
  required StarColorTheme source,
}) {
  return current.copyWith(
    textPrimary: source.textPrimary,
    textSecondary: source.textSecondary,
    textTertiary: source.textTertiary,
    textPrimaryMuted: source.textPrimaryMuted,
    textChat: source.textChat,
    textChatMuted: source.textChatMuted,
    textLink: source.textLink,
    textTertiaryMuted: source.textTertiaryMuted,
    textTertiarySecondary: source.textTertiarySecondary,
    textCode: source.textCode,
    bgCode: source.bgCode,
    bgCodeBlock: source.bgCodeBlock,
    bgTableHeader: source.bgTableHeader,
    bgTableRowOdd: source.bgTableRowOdd,
    bgTableRowEven: source.bgTableRowEven,
  );
}

StarTextTheme overlayChatWallpaperTextStyles({
  required StarTextTheme current,
  required StarColorTheme colors,
}) {
  return current.copyWith(
    heading: current.heading.copyWith(color: colors.textPrimary),
    channelName: current.channelName.copyWith(color: colors.textPrimary),
    username: current.username.copyWith(color: colors.textPrimary),
    messageText: current.messageText.copyWith(color: colors.textChat),
    codeText: current.codeText.copyWith(color: colors.textCode),
    bodyMedium: current.bodyMedium.copyWith(color: colors.textPrimary),
    bodySmall: current.bodySmall.copyWith(color: colors.textPrimaryMuted),
    label: current.label.copyWith(color: colors.textPrimary),
    timestamp: current.timestamp.copyWith(color: colors.textPrimaryMuted),
    smallText: current.smallText.copyWith(color: colors.textPrimaryMuted),
    categoryName: current.categoryName.copyWith(color: colors.textPrimaryMuted),
    inputText: current.inputText.copyWith(color: colors.textChat),
    inputHint: current.inputHint.copyWith(color: colors.textChatMuted),
    embedTitle: current.embedTitle.copyWith(color: colors.textLink),
    embedDescription: current.embedDescription.copyWith(color: colors.textChat),
    embedFooter: current.embedFooter.copyWith(color: colors.textPrimaryMuted),
    quote: current.quote.copyWith(color: colors.textSecondary),
    quoteLink: current.quoteLink.copyWith(color: colors.textLink),
  );
}
