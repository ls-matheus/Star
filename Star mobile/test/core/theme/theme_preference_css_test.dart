import 'package:flutter_test/flutter_test.dart';
import 'package:star_app/core/theme/star_color_theme.dart';
import 'package:star_app/core/theme/star_layout_theme.dart';
import 'package:star_app/core/theme/star_text_theme.dart';
import 'package:star_app/core/theme/star_theme.dart';
import 'package:star_app/core/theme/star_theme_mode.dart';
import 'package:star_app/core/theme/providers/theme_preference_provider.dart';
import 'package:star_app/core/theme/theme_color_editor.dart';
import 'package:star_app/material_ui.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ThemePreferenceState custom theme css', () {
    test('builds color themes with brand primary override', () {
      const css = ':root { --brand-primary: #ff5500; }';
      final ThemePreferenceState state = ThemePreferenceState(
        customThemeCss: css,
      );
      expect(state.darkColorTheme.brandPrimary, const Color(0xFFFF5500));
      expect(state.darkLegacyColorTheme.brandPrimary, const Color(0xFFFF5500));
      expect(state.lightColorTheme.brandPrimary, const Color(0xFFFF5500));
      expect(state.coalColorTheme.brandPrimary, const Color(0xFFFF5500));
      expect(state.colorTheme.brandPrimary, const Color(0xFFFF5500));
    });

    test('builds color themes with brand primary override in coal mode', () {
      const css = ':root { --brand-primary: #ff5500; }';
      final ThemePreferenceState state = ThemePreferenceState(
        mode: StarThemeMode.coal,
        customThemeCss: css,
      );
      expect(state.coalColorTheme.brandPrimary, const Color(0xFFFF5500));
      expect(state.colorTheme.brandPrimary, const Color(0xFFFF5500));
    });

    test(
      'copyWith rebuilds dark theme for scoped mobile override over root',
      () {
        const existing = ':root { --brand-primary: #0000ff; }';
        final String scoped = upsertScopedThemeColor(
          customThemeCss: existing,
          editingMode: StarThemeMode.dark,
          cssVariable: '--brand-primary',
          hexValue: '#ff5500',
        );
        final ThemePreferenceState state = ThemePreferenceState(
          customThemeCss: existing,
        ).copyWith(customThemeCss: scoped);
        expect(state.darkColorTheme.brandPrimary, const Color(0xFFFF5500));
        expect(state.customThemeCss, scoped);
      },
    );

    test('applies brand primary into Material ThemeData extensions', () {
      const css = ':root { --brand-primary: #ff5500; }';
      final ThemePreferenceState state = ThemePreferenceState(
        customThemeCss: css,
      );
      final ThemeData theme = buildStarTheme(
        colorTheme: state.colorTheme,
        textTheme: StarTextTheme.fromColors(state.colorTheme),
        layoutTheme: StarLayoutTheme.scaled(),
      );
      final StarColorTheme? colors = theme.extension<StarColorTheme>();
      expect(colors, isNotNull);
      expect(colors!.brandPrimary, const Color(0xFFFF5500));
      expect(theme.colorScheme.primary, const Color(0xFFFF5500));
    });
  });
}
