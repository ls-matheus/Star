import 'package:star_app/core/theme/star_theme_extension.dart';
import 'package:star_app/features/ui/ui.dart';
import 'package:star_app/l10n/generated/star_localizations.dart';
import 'package:star_app/material_ui.dart';
import 'package:star_app/shared/icons/phosphor.dart';

class ApplicationDangerSection extends StatelessWidget {
  const ApplicationDangerSection({
    required this.isDeleting,
    required this.onDelete,
    super.key,
  });

  final bool isDeleting;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final StarLocalizations l10n = StarLocalizations.of(context);
    return StarSettingsSection(
      title: l10n.applicationsDangerTitle,
      description: l10n.applicationsDangerSubtitle,
      children: [
        Text(
          l10n.applicationsDangerHelper,
          style: context.textStyles.bodySmall.copyWith(
            color: context.colors.textPrimaryMuted,
          ),
        ),
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: StarButton.dangerPrimary(
            onPressed: isDeleting ? null : onDelete,
            label: l10n.applicationsDelete,
            icon: PhosphorIconsFill.trash,
            isLoading: isDeleting,
            fitContent: true,
          ),
        ),
      ],
    );
  }
}
