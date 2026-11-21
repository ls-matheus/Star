import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:star_app/core/theme/star_color_override_scope.dart';
import 'package:star_app/core/theme/star_text_theme.dart';
import 'package:star_app/core/theme/star_theme_mode.dart';
import 'package:star_app/core/theme/providers/theme_preference_provider.dart';
import 'package:star_app/material_ui.dart';

class ThemeColorsPreviewTheme extends ConsumerWidget {
  const ThemeColorsPreviewTheme({
    required this.editingMode,
    required this.child,
    super.key,
  });

  final StarThemeMode editingMode;
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themePref = ref.watch(themePreferenceProvider);
    final colors = themePref.colorThemeForMode(editingMode);
    final textStyles = StarTextTheme.fromColors(colors);

    return StarColorOverrideScope(
      colors: colors,
      textStyles: textStyles,
      child: child,
    );
  }
}
