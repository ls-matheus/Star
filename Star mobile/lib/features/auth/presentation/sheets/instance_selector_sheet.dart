import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:star_app/core/instance/instance_config_snapshot.dart';
import 'package:star_app/core/providers/instance/active_instance_provider.dart';
import 'package:star_app/features/auth/presentation/widgets/instance_selector.dart';
import 'package:star_app/features/auth/providers/instance_selector_provider.dart';
import 'package:star_app/features/ui/ui.dart';
import 'package:star_app/l10n/generated/star_localizations.dart';
import 'package:star_app/material_ui.dart';

Future<void> showInstanceSelectorSheet(BuildContext context) async {
  final StarLocalizations l10n = StarLocalizations.of(context);
  final ProviderContainer container = ProviderScope.containerOf(context);
  final InstanceSelectorState? committedSelection = container
      .read(instanceSelectorProvider)
      .asData
      ?.value;
  final InstanceConfigSnapshot committedActiveInstance = container.read(
    activeInstanceProvider,
  );
  final bool? connected = await StarBottomSheet.show<bool>(
    context,
    title: l10n.instanceSheetTitle,
    builder: (sheetContext, _) => StarBottomSheetContent(
      child: InstanceSelectorControl(
        enabled: true,
        onConnected: () => Navigator.of(sheetContext).pop(true),
      ),
    ),
  );
  if (connected != true && committedSelection != null) {
    container
        .read(instanceSelectorProvider.notifier)
        .restoreCommittedSelection(
          selection: committedSelection,
          activeInstance: committedActiveInstance,
        );
  }
}
