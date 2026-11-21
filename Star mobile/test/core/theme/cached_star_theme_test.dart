import 'package:flutter_test/flutter_test.dart';
import 'package:star_app/core/theme/star_text_theme.dart';
import 'package:star_app/core/theme/star_theme.dart';
import 'package:star_app/core/theme/providers/theme_preference_provider.dart';
import 'package:star_app/material_ui.dart';

void main() {
  test('rebuilding the preference state keeps the same color themes', () {
    final ThemePreferenceState first = ThemePreferenceState(
      customThemeCss: ':root { --brand-primary: #123456; }',
    );
    final ThemePreferenceState second = ThemePreferenceState(
      customThemeCss: ':root { --brand-primary: #123456; }',
    );

    expect(identical(first.darkColorTheme, second.darkColorTheme), isTrue);
    expect(identical(first.lightColorTheme, second.lightColorTheme), isTrue);
    expect(identical(first.coalColorTheme, second.coalColorTheme), isTrue);
    expect(
      identical(first.darkLegacyColorTheme, second.darkLegacyColorTheme),
      isTrue,
    );
  });

  test('changing theme inputs produces new color themes', () {
    final ThemePreferenceState base = ThemePreferenceState();
    final ThemePreferenceState desaturated = ThemePreferenceState(
      saturationFactor: 0.5,
    );
    final ThemePreferenceState styled = ThemePreferenceState(
      customThemeCss: ':root { --brand-primary: #654321; }',
    );

    expect(identical(base.darkColorTheme, desaturated.darkColorTheme), isFalse);
    expect(
      identical(desaturated.darkColorTheme, styled.darkColorTheme),
      isFalse,
    );
    expect(styled.saturationFactor, 1.0);
  });

  test(
    'cachedStarTheme returns one ThemeData per color theme and brightness',
    () {
      final ThemePreferenceState state = ThemePreferenceState();

      final ThemeData dark = cachedStarTheme(
        colorTheme: state.darkColorTheme,
      );
      final ThemeData light = cachedStarTheme(
        colorTheme: state.lightColorTheme,
        brightness: Brightness.light,
      );

      expect(
        identical(dark, cachedStarTheme(colorTheme: state.darkColorTheme)),
        isTrue,
      );
      expect(
        identical(
          light,
          cachedStarTheme(
            colorTheme: state.lightColorTheme,
            brightness: Brightness.light,
          ),
        ),
        isTrue,
      );
      expect(dark.brightness, Brightness.dark);
      expect(light.brightness, Brightness.light);
    },
  );

  test('forColors shares one text theme per color theme', () {
    final ThemePreferenceState state = ThemePreferenceState();

    expect(
      identical(
        StarTextTheme.forColors(state.darkColorTheme),
        state.darkTextTheme,
      ),
      isTrue,
    );
    expect(identical(state.darkTextTheme, state.lightTextTheme), isFalse);
  });
}
