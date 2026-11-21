import 'package:star_app/core/theme/star_theme_extension.dart';
import 'package:star_app/material_ui.dart';

class AuthFormErrorText extends StatelessWidget {
  const AuthFormErrorText(this.errorText, {super.key});

  final String errorText;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      label: errorText,
      child: ExcludeSemantics(
        child: Text(
          errorText,
          style: context.textStyles.bodySmall.copyWith(
            color: context.colors.textDanger,
          ),
        ),
      ),
    );
  }
}
