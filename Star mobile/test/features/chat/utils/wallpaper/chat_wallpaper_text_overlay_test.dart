import 'package:flutter_test/flutter_test.dart';
import 'package:star_app/core/theme/star_color_theme.dart';
import 'package:star_app/core/theme/star_text_theme.dart';
import 'package:star_app/core/theme/themes/dark.dart';
import 'package:star_app/core/theme/themes/light.dart';
import 'package:star_app/features/chat/utils/wallpaper/chat_wallpaper_text_overlay.dart';

void main() {
  final StarColorTheme lightColors = buildLightColorTheme();
  final StarColorTheme darkColors = buildDarkColorTheme();
  final StarTextTheme lightText = StarTextTheme.fromColors(lightColors);

  group('overlayChatWallpaperColors', () {
    test('copies dark text tokens onto a light theme', () {
      final StarColorTheme colors = overlayChatWallpaperColors(
        current: lightColors,
        source: darkColors,
      );
      final StarTextTheme text = overlayChatWallpaperTextStyles(
        current: lightText,
        colors: colors,
      );

      expect(colors.textChat, darkColors.textChat);
      expect(colors.textPrimaryMuted, darkColors.textPrimaryMuted);
      expect(colors.textLink, darkColors.textLink);
      expect(colors.bgCodeBlock, darkColors.bgCodeBlock);
      expect(colors.embedBackground, lightColors.embedBackground);
      expect(colors.markupMentionText, lightColors.markupMentionText);
      expect(text.messageText.color, darkColors.textChat);
      expect(text.messageText.fontSize, lightText.messageText.fontSize);
      expect(text.timestamp.color, darkColors.textPrimaryMuted);
    });
  });
}
