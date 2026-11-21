import 'package:flutter_test/flutter_test.dart';
import 'package:star_app/core/theme/color_families.dart';
import 'package:star_app/core/theme/color_generator.dart';
import 'package:star_app/core/theme/star_theme_mode.dart';
import 'package:star_app/core/theme/themes/dark.dart';
import 'package:star_app/core/theme/themes/dark_legacy.dart';

void main() {
  group('dark theme palettes', () {
    test('new dark uses the violet-neutral family from desktop', () {
      final dark = buildDarkColorTheme();
      final expectedPrimary = generateTone(
        hue: StarColorFamilies.neutralDark.hue,
        saturation: StarColorFamilies.neutralDark.saturation,
        lightness: 5,
      );
      expect(dark.backgroundPrimary, expectedPrimary);
      expect(StarColorFamilies.neutralDark.hue, 258);
    });

    test('legacy dark keeps the original gray-neutral family', () {
      final legacy = buildDarkLegacyColorTheme();
      final expectedPrimary = generateTone(
        hue: StarColorFamilies.legacyDark.hue,
        saturation: StarColorFamilies.legacyDark.saturation,
        lightness: 5,
      );
      expect(legacy.backgroundPrimary, expectedPrimary);
      expect(StarColorFamilies.legacyDark.hue, 220);
    });

    test('dark and legacy palettes are distinct', () {
      final dark = buildDarkColorTheme();
      final legacy = buildDarkLegacyColorTheme();
      expect(dark.backgroundPrimary, isNot(legacy.backgroundPrimary));
      expect(dark.backgroundSecondary, isNot(legacy.backgroundSecondary));
      expect(dark.textLink, isNot(legacy.textLink));
    });
  });

  group('StarThemeMode api values', () {
    test('maps dark_legacy to the SDK theme id', () {
      expect(StarThemeMode.dark.apiValue, 'dark');
      expect(StarThemeMode.darkLegacy.apiValue, 'dark_legacy');
      expect(
        StarThemeMode.fromApiValue('dark_legacy'),
        StarThemeMode.darkLegacy,
      );
      expect(
        StarThemeMode.fromApiValue('darkLegacy'),
        StarThemeMode.darkLegacy,
      );
    });
  });
}
