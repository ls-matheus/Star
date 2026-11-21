import 'package:star_app/core/theme/star_color_theme.dart';
import 'package:star_app/core/theme/star_text_theme.dart';
import 'package:star_app/material_ui.dart';

class StarColorOverrideScope extends InheritedWidget {
  const StarColorOverrideScope({
    required this.colors,
    required this.textStyles,
    required super.child,
    super.key,
  });

  final StarColorTheme? colors;
  final StarTextTheme? textStyles;

  static StarColorOverrideScope? maybeOf(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<StarColorOverrideScope>();
  }

  static bool isActiveOf(BuildContext context) {
    return maybeOf(context)?.isActive ?? false;
  }

  bool get isActive => colors != null && textStyles != null;

  @override
  bool updateShouldNotify(StarColorOverrideScope oldWidget) {
    return colors != oldWidget.colors || textStyles != oldWidget.textStyles;
  }
}
