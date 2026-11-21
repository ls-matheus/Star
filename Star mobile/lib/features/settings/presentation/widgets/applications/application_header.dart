import 'package:star_app/core/theme/star_theme_extension.dart';
import 'package:star_app/features/settings/presentation/widgets/applications/application_read_only_input.dart';
import 'package:star_app/features/ui/ui.dart';
import 'package:star_app/l10n/generated/star_localizations.dart';
import 'package:star_app/material_ui.dart';
import 'package:star_app/shared/icons/phosphor.dart';

class ApplicationHeader extends StatelessWidget {
  const ApplicationHeader({
    required this.name,
    required this.applicationId,
    required this.onBack,
    required this.onCopyId,
    super.key,
  });

  final String name;
  final String applicationId;
  final VoidCallback onBack;
  final VoidCallback onCopyId;

  @override
  Widget build(BuildContext context) {
    final StarLocalizations l10n = StarLocalizations.of(context);
    final layout = context.layout;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        StarButton.secondary(
          onPressed: onBack,
          label: l10n.applicationsBackToList,
          size: StarButtonSize.small,
          fitContent: true,
        ),
        SizedBox(height: layout.s3),
        Text(
          name,
          style: context.textStyles.heading.copyWith(
            color: context.colors.textPrimary,
          ),
        ),
        SizedBox(height: layout.s4),
        ApplicationReadOnlyInput(
          text: applicationId,
          label: l10n.applicationsId,
          trailing: StarButton.secondary(
            onPressed: onCopyId,
            label: l10n.applicationsCopyId,
            icon: PhosphorIconsBold.copy,
            size: StarButtonSize.compact,
            fitContent: true,
          ),
        ),
      ],
    );
  }
}
