import 'package:star_app/core/theme/star_color_theme.dart';
import 'package:star_app/core/theme/star_fonts.dart';
import 'package:star_app/material_ui.dart';

class StarTextTheme extends ThemeExtension<StarTextTheme> {
  const StarTextTheme({
    required this.heading,
    required this.channelName,
    required this.username,
    required this.messageText,
    required this.codeText,
    required this.bodyMedium,
    required this.bodySmall,
    required this.label,
    required this.timestamp,
    required this.smallText,
    required this.categoryName,
    required this.inputText,
    required this.inputHint,
    required this.embedTitle,
    required this.embedDescription,
    required this.embedFooter,
    required this.quote,
    required this.quoteLink,
  });

  static final Expando<StarTextTheme> _byColors = Expando<StarTextTheme>();

  factory StarTextTheme.forColors(StarColorTheme colors) {
    return _byColors[colors] ??= StarTextTheme.fromColors(colors);
  }

  factory StarTextTheme.fromColors(StarColorTheme colors) {
    return StarTextTheme(
      heading: TextStyle(
        fontFamily: StarFonts.brand,
        fontSize: 20,
        fontWeight: FontWeight.w400,
        color: colors.textPrimary,
      ),
      channelName: TextStyle(
        fontFamily: StarFonts.sans,
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: colors.textPrimary,
      ),
      username: TextStyle(
        fontFamily: StarFonts.sans,
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: colors.textPrimary,
      ),
      messageText: TextStyle(
        fontFamily: StarFonts.sans,
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: colors.textChat,
        height: 1.375,
      ),
      codeText: const TextStyle(
        fontFamily: StarFonts.mono,
        fontSize: 16,
        fontWeight: FontWeight.w400,
        height: 1.375,
      ),
      bodyMedium: TextStyle(
        fontFamily: StarFonts.sans,
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: colors.textPrimary,
      ),
      bodySmall: TextStyle(
        fontFamily: StarFonts.sans,
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: colors.textPrimaryMuted,
      ),
      label: TextStyle(
        fontFamily: StarFonts.sans,
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: colors.textPrimary,
      ),
      timestamp: TextStyle(
        fontFamily: StarFonts.sans,
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: colors.textPrimaryMuted,
      ),
      smallText: TextStyle(
        fontFamily: StarFonts.sans,
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: colors.textPrimaryMuted,
        letterSpacing: 0.02,
      ),
      categoryName: TextStyle(
        fontFamily: StarFonts.sans,
        fontSize: 14,
        fontWeight: FontWeight.w600,
        height: 20 / 14,
        color: colors.textPrimaryMuted,
      ),
      inputText: TextStyle(
        fontFamily: StarFonts.sans,
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: colors.textChat,
      ),
      inputHint: TextStyle(
        fontFamily: StarFonts.sans,
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: colors.textChatMuted,
      ),
      embedTitle: TextStyle(
        fontFamily: StarFonts.sans,
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: colors.textLink,
      ),
      embedDescription: TextStyle(
        fontFamily: StarFonts.sans,
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: colors.textChat,
        height: 1.3,
      ),
      embedFooter: TextStyle(
        fontFamily: StarFonts.sans,
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: colors.textPrimaryMuted,
      ),
      quote: TextStyle(
        fontFamily: StarFonts.sans,
        fontSize: 14,
        fontWeight: FontWeight.w400,
        fontStyle: FontStyle.italic,
        color: colors.textSecondary,
        height: 1.4,
      ),
      quoteLink: TextStyle(
        fontFamily: StarFonts.sans,
        fontSize: 14,
        fontWeight: FontWeight.w400,
        fontStyle: FontStyle.italic,
        color: colors.textLink,
        height: 1.4,
        decoration: TextDecoration.none,
      ),
    );
  }

  final TextStyle heading;
  final TextStyle channelName;
  final TextStyle username;
  final TextStyle messageText;
  final TextStyle codeText;
  final TextStyle bodyMedium;
  final TextStyle bodySmall;
  final TextStyle label;
  final TextStyle timestamp;
  final TextStyle smallText;
  final TextStyle categoryName;
  final TextStyle inputText;
  final TextStyle inputHint;
  final TextStyle embedTitle;
  final TextStyle embedDescription;
  final TextStyle embedFooter;
  final TextStyle quote;
  final TextStyle quoteLink;

  @override
  StarTextTheme copyWith({
    TextStyle? heading,
    TextStyle? channelName,
    TextStyle? username,
    TextStyle? messageText,
    TextStyle? codeText,
    TextStyle? bodyMedium,
    TextStyle? bodySmall,
    TextStyle? label,
    TextStyle? timestamp,
    TextStyle? smallText,
    TextStyle? categoryName,
    TextStyle? inputText,
    TextStyle? inputHint,
    TextStyle? embedTitle,
    TextStyle? embedDescription,
    TextStyle? embedFooter,
    TextStyle? quote,
    TextStyle? quoteLink,
  }) {
    return StarTextTheme(
      heading: heading ?? this.heading,
      channelName: channelName ?? this.channelName,
      username: username ?? this.username,
      messageText: messageText ?? this.messageText,
      codeText: codeText ?? this.codeText,
      bodyMedium: bodyMedium ?? this.bodyMedium,
      bodySmall: bodySmall ?? this.bodySmall,
      label: label ?? this.label,
      timestamp: timestamp ?? this.timestamp,
      smallText: smallText ?? this.smallText,
      categoryName: categoryName ?? this.categoryName,
      inputText: inputText ?? this.inputText,
      inputHint: inputHint ?? this.inputHint,
      embedTitle: embedTitle ?? this.embedTitle,
      embedDescription: embedDescription ?? this.embedDescription,
      embedFooter: embedFooter ?? this.embedFooter,
      quote: quote ?? this.quote,
      quoteLink: quoteLink ?? this.quoteLink,
    );
  }

  @override
  StarTextTheme lerp(StarTextTheme? other, double t) {
    if (other is! StarTextTheme) {
      return this;
    }
    return StarTextTheme(
      heading: TextStyle.lerp(heading, other.heading, t)!,
      channelName: TextStyle.lerp(channelName, other.channelName, t)!,
      username: TextStyle.lerp(username, other.username, t)!,
      messageText: TextStyle.lerp(messageText, other.messageText, t)!,
      codeText: TextStyle.lerp(codeText, other.codeText, t)!,
      bodyMedium: TextStyle.lerp(bodyMedium, other.bodyMedium, t)!,
      bodySmall: TextStyle.lerp(bodySmall, other.bodySmall, t)!,
      label: TextStyle.lerp(label, other.label, t)!,
      timestamp: TextStyle.lerp(timestamp, other.timestamp, t)!,
      smallText: TextStyle.lerp(smallText, other.smallText, t)!,
      categoryName: TextStyle.lerp(categoryName, other.categoryName, t)!,
      inputText: TextStyle.lerp(inputText, other.inputText, t)!,
      inputHint: TextStyle.lerp(inputHint, other.inputHint, t)!,
      embedTitle: TextStyle.lerp(embedTitle, other.embedTitle, t)!,
      embedDescription: TextStyle.lerp(
        embedDescription,
        other.embedDescription,
        t,
      )!,
      embedFooter: TextStyle.lerp(embedFooter, other.embedFooter, t)!,
      quote: TextStyle.lerp(quote, other.quote, t)!,
      quoteLink: TextStyle.lerp(quoteLink, other.quoteLink, t)!,
    );
  }
}
