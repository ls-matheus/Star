import 'package:star_app/core/theme/star_theme_extension.dart';
import 'package:star_app/material_ui.dart';

class ChannelSettingsControlRow extends StatelessWidget {
  const ChannelSettingsControlRow({
    required this.label,
    required this.child,
    this.description,
    super.key,
  });

  final String label;
  final String? description;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final layout = context.layout;
    final textStyles = context.textStyles;
    final colors = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(
          label,
          style: textStyles.bodyMedium.copyWith(fontWeight: FontWeight.w500),
        ),
        if (description != null) ...<Widget>[
          SizedBox(height: layout.s1),
          Text(
            description!,
            style: textStyles.bodySmall.copyWith(color: colors.textSecondary),
          ),
        ],
        SizedBox(height: layout.s2),
        child,
      ],
    );
  }
}
