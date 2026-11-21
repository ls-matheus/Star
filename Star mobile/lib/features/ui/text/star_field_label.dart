import 'package:star_app/core/theme/star_theme_extension.dart';
import 'package:star_app/features/ui/preview/star_widget_preview.dart';
import 'package:star_app/material_ui.dart';

class StarFieldLabel extends StatelessWidget {
  const StarFieldLabel(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      header: true,
      child: Text(
        text,
        style: context.textStyles.bodySmall.copyWith(
          color: context.colors.textPrimary,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

@StarWidgetPreview(name: 'Default', group: 'StarFieldLabel')
Widget starFieldLabelPreview() {
  return const StarFieldLabel('Display name');
}
