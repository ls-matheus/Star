import 'package:cupertino_ui/cupertino_ui.dart'
    show CupertinoTheme, CupertinoThemeData;
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:star_app/core/theme/star_color_theme.dart';
import 'package:star_app/core/theme/star_theme.dart';
import 'package:star_app/core/theme/providers/theme_preference_provider.dart';
import 'package:star_app/material_ui.dart';

class StarfieldDarkTheme extends ConsumerWidget {
  const StarfieldDarkTheme({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (Theme.of(context).brightness == Brightness.dark) {
      return child;
    }
    final StarColorTheme darkColors = ref.watch(
      themePreferenceProvider.select(
        (ThemePreferenceState state) => state.darkColorTheme,
      ),
    );
    final ThemeData theme = cachedStarTheme(colorTheme: darkColors);
    final CupertinoThemeData cupertinoTheme = CupertinoTheme.of(context)
        .copyWith(
          brightness: Brightness.dark,
          scaffoldBackgroundColor: theme.scaffoldBackgroundColor,
        );
    return Theme(
      data: theme,
      child: CupertinoTheme(
        data: cupertinoTheme,
        child: AnnotatedRegion<SystemUiOverlayStyle>(
          value: starSystemUiOverlayStyle(
            brightness: Brightness.dark,
            navigationBarColor: theme.scaffoldBackgroundColor,
          ),
          child: child,
        ),
      ),
    );
  }
}
