import 'package:star_app/core/theme/star_theme_extension.dart';
import 'package:star_app/features/ui/preview/star_widget_preview.dart';
import 'package:star_app/material_ui.dart';

class StarSubsectionLabel extends StatelessWidget {
  const StarSubsectionLabel(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Semantics(
      header: true,
      child: Text(
        text,
        style: context.textStyles.smallText.copyWith(
          color: colors.textTertiaryMuted,
        ),
      ),
    );
  }
}

@StarWidgetPreview(name: 'Default', group: 'StarSubsectionLabel')
Widget starSubsectionLabelPreview() {
  return const StarSubsectionLabel('Additional Groups');
}
