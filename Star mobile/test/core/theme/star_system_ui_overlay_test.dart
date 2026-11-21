import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:star_app/core/theme/star_layout_theme.dart';
import 'package:star_app/core/theme/star_text_theme.dart';
import 'package:star_app/core/theme/star_theme.dart';
import 'package:star_app/core/theme/themes/dark.dart';
import 'package:star_app/core/theme/themes/light.dart';
import 'package:star_app/material_ui.dart';

void main() {
  group('starSystemUiOverlayStyle', () {
    test('dark theme uses light icons and the theme nav color', () {
      const Color navColor = Color(0xFF1A1625);
      final SystemUiOverlayStyle style = starSystemUiOverlayStyle(
        brightness: Brightness.dark,
        navigationBarColor: navColor,
      );

      expect(style.systemNavigationBarColor, navColor);
      expect(style.systemNavigationBarIconBrightness, Brightness.light);
      expect(style.systemNavigationBarContrastEnforced, isFalse);
      expect(style.statusBarIconBrightness, Brightness.light);
      expect(style.statusBarBrightness, Brightness.dark);
      expect(style.systemStatusBarContrastEnforced, isFalse);
    });

    test('light theme uses dark icons and the theme nav color', () {
      const Color navColor = Color(0xFFF2F3F5);
      final SystemUiOverlayStyle style = starSystemUiOverlayStyle(
        brightness: Brightness.light,
        navigationBarColor: navColor,
      );

      expect(style.systemNavigationBarColor, navColor);
      expect(style.systemNavigationBarIconBrightness, Brightness.dark);
      expect(style.statusBarIconBrightness, Brightness.dark);
      expect(style.statusBarBrightness, Brightness.light);
    });
  });

  group('buildStarTheme system overlay', () {
    test('dark material theme carries overlay from color tokens', () {
      final colorTheme = buildDarkColorTheme();
      final ThemeData theme = buildStarTheme(
        colorTheme: colorTheme,
        textTheme: StarTextTheme.fromColors(colorTheme),
        layoutTheme: StarLayoutTheme.scaled(),
      );
      final SystemUiOverlayStyle? style = theme.appBarTheme.systemOverlayStyle;

      expect(style, isNotNull);
      expect(style!.systemNavigationBarColor, colorTheme.backgroundSecondary);
      expect(style.systemNavigationBarIconBrightness, Brightness.light);
      expect(style.systemNavigationBarContrastEnforced, isFalse);
    });

    test('light material theme carries overlay from color tokens', () {
      final colorTheme = buildLightColorTheme();
      final ThemeData theme = buildStarTheme(
        colorTheme: colorTheme,
        textTheme: StarTextTheme.fromColors(colorTheme),
        layoutTheme: StarLayoutTheme.scaled(),
        brightness: Brightness.light,
      );
      final SystemUiOverlayStyle? style = theme.appBarTheme.systemOverlayStyle;

      expect(style, isNotNull);
      expect(style!.systemNavigationBarColor, colorTheme.backgroundSecondary);
      expect(style.systemNavigationBarIconBrightness, Brightness.dark);
    });
  });

  group('themed overlay vs OS brightness', () {
    const double statusBarHeight = 25;
    const double navigationBarHeight = 54;
    const double deviceHeight = 960;
    const double deviceWidth = 480;
    const double devicePixelRatio = 2;

    void setupAndroidChrome(WidgetTester tester) {
      tester.platformDispatcher.platformBrightnessTestValue = Brightness.light;
      addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);

      const FakeViewPadding padding = FakeViewPadding(
        top: statusBarHeight * devicePixelRatio,
        bottom: navigationBarHeight * devicePixelRatio,
      );
      addTearDown(tester.view.reset);
      tester.view
        ..viewPadding = padding
        ..padding = padding
        ..devicePixelRatio = devicePixelRatio
        ..physicalSize = const Size(
          deviceWidth * devicePixelRatio,
          deviceHeight * devicePixelRatio,
        );
    }

    testWidgets(
      'dark app theme colors the Android nav bar while the OS is light',
      (WidgetTester tester) async {
        setupAndroidChrome(tester);
        final colorTheme = buildDarkColorTheme();
        final ThemeData theme = buildStarTheme(
          colorTheme: colorTheme,
          textTheme: StarTextTheme.fromColors(colorTheme),
          layoutTheme: StarLayoutTheme.scaled(),
        );

        await tester.pumpWidget(
          MaterialApp(
            theme: theme,
            darkTheme: theme,
            themeMode: ThemeMode.dark,
            builder: (BuildContext context, Widget? child) {
              return AnnotatedRegion<SystemUiOverlayStyle>(
                value: Theme.of(context).appBarTheme.systemOverlayStyle!,
                child: child ?? const SizedBox.shrink(),
              );
            },
            home: const SizedBox.expand(),
          ),
        );
        await tester.pumpAndSettle();

        expect(
          SystemChrome.latestStyle?.systemNavigationBarColor,
          colorTheme.backgroundSecondary,
        );
        expect(
          SystemChrome.latestStyle?.systemNavigationBarIconBrightness,
          Brightness.light,
        );
        expect(
          SystemChrome.latestStyle?.systemNavigationBarContrastEnforced,
          isFalse,
        );
      },
      variant: TargetPlatformVariant.only(TargetPlatform.android),
    );
  });
}
