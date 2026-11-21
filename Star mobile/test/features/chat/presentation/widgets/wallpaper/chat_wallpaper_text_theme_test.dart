import 'package:flutter_test/flutter_test.dart';
import 'package:star_app/core/theme/star_color_override_scope.dart';
import 'package:star_app/core/theme/star_color_theme.dart';
import 'package:star_app/core/theme/star_layout_theme.dart';
import 'package:star_app/core/theme/star_text_theme.dart';
import 'package:star_app/core/theme/star_theme.dart';
import 'package:star_app/core/theme/star_theme_extension.dart';
import 'package:star_app/core/theme/themes/dark.dart';
import 'package:star_app/core/theme/themes/light.dart';
import 'package:star_app/features/chat/presentation/widgets/wallpaper/chat_wallpaper_text_theme.dart';
import 'package:star_app/features/chat/utils/wallpaper/chat_wallpaper_text_overlay.dart';
import 'package:star_app/material_ui.dart';

void main() {
  final StarColorTheme lightColors = buildLightColorTheme();
  final StarColorTheme darkColors = buildDarkColorTheme();
  final ThemeData lightTheme = buildStarTheme(
    colorTheme: lightColors,
    textTheme: StarTextTheme.fromColors(lightColors),
    layoutTheme: StarLayoutTheme.scaled(),
    brightness: Brightness.light,
  );

  testWidgets('override colors leave ThemeData on the app theme', (
    WidgetTester tester,
  ) async {
    final StarColorTheme mixed = overlayChatWallpaperColors(
      current: lightColors,
      source: darkColors,
    );
    late Color starColor;
    late Color themeColor;
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Theme(
          data: lightTheme,
          child: StarColorOverrideScope(
            colors: mixed,
            textStyles: overlayChatWallpaperTextStyles(
              current: StarTextTheme.fromColors(lightColors),
              colors: mixed,
            ),
            child: Builder(
              builder: (BuildContext context) {
                starColor = context.colors.textChat;
                themeColor = Theme.of(
                  context,
                ).extension<StarColorTheme>()!.textChat;
                return const SizedBox.shrink();
              },
            ),
          ),
        ),
      ),
    );
    expect(starColor, darkColors.textChat);
    expect(themeColor, lightColors.textChat);
  });

  testWidgets('ChatSurfaceTheme builder uses the app theme', (
    WidgetTester tester,
  ) async {
    final StarColorTheme mixed = overlayChatWallpaperColors(
      current: lightColors,
      source: darkColors,
    );
    late Color captured;
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Theme(
          data: lightTheme,
          child: StarColorOverrideScope(
            colors: mixed,
            textStyles: overlayChatWallpaperTextStyles(
              current: StarTextTheme.fromColors(lightColors),
              colors: mixed,
            ),
            child: ChatSurfaceTheme(
              builder: (BuildContext context) {
                captured = context.colors.textChat;
                return const SizedBox.shrink();
              },
            ),
          ),
        ),
      ),
    );
    expect(captured, lightColors.textChat);
  });
}
