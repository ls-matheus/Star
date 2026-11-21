import 'package:star_app/core/theme/star_color_override_scope.dart';
import 'package:star_app/core/theme/star_color_theme.dart';
import 'package:star_app/core/theme/star_layout_theme.dart';
import 'package:star_app/core/theme/star_motion_theme.dart';
import 'package:star_app/core/theme/star_text_theme.dart';
import 'package:star_app/material_ui.dart';

extension StarThemeX on BuildContext {
  StarColorTheme get colors =>
      StarColorOverrideScope.maybeOf(this)?.colors ??
      Theme.of(this).extension<StarColorTheme>()!;
  StarTextTheme get textStyles =>
      StarColorOverrideScope.maybeOf(this)?.textStyles ??
      Theme.of(this).extension<StarTextTheme>()!;
  StarLayoutTheme get layout =>
      Theme.of(this).extension<StarLayoutTheme>()!;

  StarMotionTheme get motion {
    if (MediaQuery.disableAnimationsOf(this)) {
      return const StarMotionTheme.reduced();
    }
    if (StarMotionSuppression.isSuppressed(this)) {
      return const StarMotionTheme.suppressed();
    }
    return Theme.of(this).extension<StarMotionTheme>()!;
  }
}
