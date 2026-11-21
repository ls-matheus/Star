import 'package:star_app/core/theme/star_theme_extension.dart';
import 'package:star_app/l10n/generated/star_localizations.dart';
import 'package:star_app/material_ui.dart';

class StarUserTag extends StatelessWidget {
  const StarUserTag({required this.isSystem, this.label, super.key});

  final bool isSystem;
  final String? label;

  @override
  Widget build(BuildContext context) {
    final StarLocalizations l10n = StarLocalizations.of(context);
    final String label =
        this.label ?? (isSystem ? l10n.userTagSystem : l10n.userTagBot);
    final colors = context.colors;
    return Container(
      constraints: const BoxConstraints(minHeight: 15),
      padding: const EdgeInsets.symmetric(horizontal: 5.5, vertical: 2),
      decoration: BoxDecoration(
        color: colors.brandPrimary,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label.toUpperCase(),
        style: context.textStyles.smallText.copyWith(
          color: colors.brandPrimaryFill,
          fontSize: 10,
          height: 1,
        ),
      ),
    );
  }
}
