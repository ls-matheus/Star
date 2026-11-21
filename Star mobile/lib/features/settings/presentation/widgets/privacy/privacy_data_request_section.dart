import 'dart:async';

import 'package:star_app/core/theme/star_theme_extension.dart';
import 'package:star_app/features/settings/domain/privacy_data_request.dart';
import 'package:star_app/features/settings/presentation/sheets/privacy_data_request_sheet.dart';
import 'package:star_app/features/ui/ui.dart';
import 'package:star_app/l10n/generated/star_localizations.dart';
import 'package:star_app/material_ui.dart';

class PrivacyDataExportSection extends StatelessWidget {
  const PrivacyDataExportSection({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = StarLocalizations.of(context);
    final colors = context.colors;
    final layout = context.layout;

    return StarSettingsSection(
      sectionId: 'data-export',
      title: l10n.privacyDashboardDataExportSection,
      children: [
        StarSettingsSubsection(
          children: [
            Text(
              l10n.privacyDashboardDataExportDesc,
              style: context.textStyles.bodySmall.copyWith(
                color: colors.textPrimaryMuted,
              ),
            ),
            SizedBox(height: layout.s3),
            SizedBox(
              width: double.infinity,
              child: StarButton.primary(
                label: l10n.privacyDashboardExportMyData,
                onPressed: () => unawaited(
                  PrivacyDataRequestSheet.show(
                    context,
                    variant: PrivacyDataRequestVariant.export,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class PrivacyDataDeletionSection extends StatelessWidget {
  const PrivacyDataDeletionSection({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = StarLocalizations.of(context);
    final colors = context.colors;
    final layout = context.layout;

    return StarSettingsSection(
      sectionId: 'data-deletion',
      title: l10n.privacyDashboardDataDeletionSection,
      children: [
        StarSettingsSubsection(
          children: [
            Text(
              l10n.privacyDashboardDataDeletionDesc,
              style: context.textStyles.bodySmall.copyWith(
                color: colors.textPrimaryMuted,
              ),
            ),
            SizedBox(height: layout.s3),
            SizedBox(
              width: double.infinity,
              child: StarButton.dangerPrimary(
                label: l10n.privacyDashboardDeleteMyMessages,
                onPressed: () => unawaited(
                  PrivacyDataRequestSheet.show(
                    context,
                    variant: PrivacyDataRequestVariant.delete,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
