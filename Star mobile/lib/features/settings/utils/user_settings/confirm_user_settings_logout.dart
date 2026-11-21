import 'package:star_app/features/ui/settings/star_settings_confirm_sheet.dart';
import 'package:star_app/l10n/generated/star_localizations.dart';
import 'package:star_app/material_ui.dart';

Future<bool> confirmUserSettingsLogout(BuildContext context) async {
  final StarLocalizations l10n = StarLocalizations.of(context);
  final bool? confirmed = await showStarSettingsConfirmSheet(
    context,
    title: l10n.userSettingsLogOutConfirmTitle,
    description: l10n.userSettingsLogOutConfirmDescription,
    confirmLabel: l10n.signOut,
    isDanger: true,
  );
  return confirmed ?? false;
}
