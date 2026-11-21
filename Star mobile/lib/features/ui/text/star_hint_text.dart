import 'package:star_app/core/theme/star_theme_extension.dart';
import 'package:star_app/features/ui/preview/star_widget_preview.dart';
import 'package:star_app/material_ui.dart';

class StarHintText extends StatelessWidget {
  const StarHintText(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: context.textStyles.bodySmall.copyWith(
        color: context.colors.textPrimaryMuted,
      ),
    );
  }
}

@StarWidgetPreview(name: 'Default', group: 'StarHintText')
Widget starHintTextPreview() {
  return const StarHintText('Optional. Shown on your profile and mentions.');
}
