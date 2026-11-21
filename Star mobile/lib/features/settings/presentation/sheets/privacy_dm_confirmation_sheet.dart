import 'package:star_app/core/theme/star_theme_extension.dart';
import 'package:star_app/features/settings/presentation/widgets/wide_settings_content_layout.dart';
import 'package:star_app/features/ui/ui.dart';
import 'package:star_app/l10n/generated/star_localizations.dart';
import 'package:star_app/material_ui.dart';

class PrivacyDmConfirmationSheet extends StatelessWidget {
  const PrivacyDmConfirmationSheet({
    required this.allowing,
    required this.isBots,
    super.key,
  });

  final bool allowing;
  final bool isBots;

  static Future<bool?> show(
    BuildContext context, {
    required bool allowing,
    required bool isBots,
  }) {
    final l10n = StarLocalizations.of(context);
    final String title;
    if (allowing && isBots) {
      title = l10n.privacyDashboardDmConfirmAllowBotsTitle;
    } else if (allowing) {
      title = l10n.privacyDashboardDmConfirmAllowMembersTitle;
    } else if (isBots) {
      title = l10n.privacyDashboardDmConfirmBlockBotsTitle;
    } else {
      title = l10n.privacyDashboardDmConfirmBlockMembersTitle;
    }

    return StarBottomSheet.show<bool>(
      context,
      title: title,
      useRootNavigator: true,
      builder: (_, _) =>
          PrivacyDmConfirmationSheet(allowing: allowing, isBots: isBots),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = StarLocalizations.of(context);
    final colors = context.colors;
    final layout = context.layout;
    final String description;
    if (allowing && isBots) {
      description = l10n.privacyDashboardDmConfirmAllowBotsDesc;
    } else if (allowing) {
      description = l10n.privacyDashboardDmConfirmAllowMembersDesc;
    } else if (isBots) {
      description = l10n.privacyDashboardDmConfirmBlockBotsDesc;
    } else {
      description = l10n.privacyDashboardDmConfirmBlockMembersDesc;
    }

    return SingleChildScrollView(
      padding: settingsSheetScrollPadding(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            description,
            style: context.textStyles.bodySmall.copyWith(
              color: colors.textPrimary,
            ),
          ),
          SizedBox(height: layout.s2),
          Text(
            l10n.privacyDashboardDmConfirmPerCommunityHint,
            style: context.textStyles.bodySmall.copyWith(
              color: colors.textPrimaryMuted,
            ),
          ),
          SizedBox(height: layout.s4),
          StarButton.primary(
            label: allowing
                ? l10n.privacyDashboardDmConfirmAllowAll
                : l10n.privacyDashboardDmConfirmBlockAll,
            onPressed: () =>
                Navigator.of(context, rootNavigator: true).pop(true),
          ),
          SizedBox(height: layout.s2),
          StarButton.secondary(
            label: l10n.privacyDashboardDmConfirmSkip,
            onPressed: () =>
                Navigator.of(context, rootNavigator: true).pop(false),
          ),
        ],
      ),
    );
  }
}
