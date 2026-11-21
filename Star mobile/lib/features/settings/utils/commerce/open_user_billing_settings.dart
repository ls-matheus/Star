import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:star_app/core/theme/star_theme_extension.dart';
import 'package:star_app/features/settings/domain/user_settings_section.dart';
import 'package:star_app/features/settings/presentation/user_settings_modal.dart';
import 'package:star_app/features/settings/utils/commerce/user_settings_billing_nav.dart';
import 'package:star_app/features/ui/bottom_sheet/star_bottom_sheet.dart';
import 'package:star_app/l10n/generated/star_localizations.dart';
import 'package:star_app/material_ui.dart';

Future<void> openUserBillingSettings(
  BuildContext context,
  UserSettingsSection section,
) {
  return UserSettingsModal.show(context, initialSection: section);
}

Future<void> openPlutoniumCommerce(
  BuildContext context,
  WidgetRef ref, {
  bool useRootNavigator = false,
}) async {
  if (userSettingsShowBillingNav(ref)) {
    await openUserBillingSettings(context, UserSettingsSection.starPlutonium);
    return;
  }
  await showPlutoniumUnavailableSheet(
    context,
    useRootNavigator: useRootNavigator,
  );
}

Future<void> showPlutoniumUnavailableSheet(
  BuildContext context, {
  bool useRootNavigator = false,
}) async {
  final StarLocalizations l10n = StarLocalizations.of(context);
  await StarBottomSheet.show<void>(
    context,
    title: l10n.plutoniumNotAvailableTitle,
    useRootNavigator: useRootNavigator,
    builder: (sheetContext, _) => Padding(
      padding: EdgeInsets.fromLTRB(
        sheetContext.layout.s4,
        sheetContext.layout.s4,
        sheetContext.layout.s4,
        0,
      ),
      child: Text(
        l10n.plutoniumNotSoldHere,
        style: sheetContext.textStyles.bodyMedium.copyWith(
          color: sheetContext.colors.textSecondary,
        ),
      ),
    ),
  );
}
