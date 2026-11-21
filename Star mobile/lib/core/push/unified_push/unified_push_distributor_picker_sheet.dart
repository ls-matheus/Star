import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:star_app/core/push/delivery/display.dart';
import 'package:star_app/core/push/services/unified_push_service.dart';
import 'package:star_app/core/push/unified_push/unified_push_functions.dart';
import 'package:star_app/core/theme/star_theme_extension.dart';
import 'package:star_app/features/settings/providers/commerce/push_delivery_details_provider.dart';
import 'package:star_app/features/ui/bottom_sheet/star_bottom_sheet.dart';
import 'package:star_app/features/ui/radio_group/star_radio_group.dart';
import 'package:star_app/l10n/generated/star_localizations.dart';
import 'package:star_app/material_ui.dart';
import 'package:star_app/shared/icons/phosphor.dart';

Future<void> showUnifiedPushDistributorPickerSheet(
  BuildContext context, {
  required WidgetRef ref,
  required List<String> distributors,
  required String? currentDistributor,
}) async {
  if (distributors.length < 2 || !context.mounted) {
    return;
  }
  final StarLocalizations l10n = StarLocalizations.of(context);
  final StarUnifiedPushFunctions functions = StarUnifiedPushFunctions();
  String? selected = currentDistributor;
  if (selected == null || !distributors.contains(selected)) {
    selected = distributors.first;
  }

  await StarBottomSheet.show<void>(
    context,
    useRootNavigator: true,
    title: l10n.notificationsPushDeliveryDistributorSheetTitle,
    builder: (sheetContext, close) {
      return StarRadioGroup<String>(
        value: selected,
        onChanged: (String value) async {
          if (value == currentDistributor) {
            close();
            return;
          }
          await functions.saveDistributor(value);
          for (final String instance
              in UnifiedPushService.instance.distributorInstances) {
            await functions.registerApp(instance);
          }
          ref.invalidate(pushDeliveryDetailsProvider);
          if (sheetContext.mounted) {
            close();
          }
        },
        items: distributors
            .map(
              (String id) => StarRadioItem<String>(
                value: id,
                label: formatUnifiedPushDistributor(id),
                leading: PhosphorIcon(
                  PhosphorIconsFill.plugs,
                  size: 20,
                  color: sheetContext.colors.textSecondary,
                ),
              ),
            )
            .toList(),
      );
    },
  );
}
