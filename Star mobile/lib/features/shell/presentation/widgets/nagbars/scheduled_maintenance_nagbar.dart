import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:star_app/features/shell/domain/service_status_maintenance.dart';
import 'package:star_app/features/shell/presentation/responsive_layout.dart';
import 'package:star_app/features/shell/presentation/widgets/nagbars/nagbar_widget.dart';
import 'package:star_app/features/shell/providers/service_status/scheduled_maintenance_dismissal_provider.dart';
import 'package:star_app/features/shell/providers/service_status/service_status_maintenance_provider.dart';
import 'package:star_app/features/shell/utils/maintenance_nagbar_message.dart';
import 'package:star_app/features/ui/nagbar/star_nagbar.dart';
import 'package:star_app/features/ui/nagbar/star_nagbar_button.dart';
import 'package:star_app/features/ui/nagbar/star_nagbar_content.dart';
import 'package:star_app/l10n/generated/star_localizations.dart';
import 'package:star_app/material_ui.dart';
import 'package:star_app/shared/external_links/external_link_handler.dart';

class ScheduledMaintenanceNagbar extends ConsumerWidget
    implements NagbarWidget {
  const ScheduledMaintenanceNagbar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ServiceStatusMaintenance? maintenance = ref.watch(
      serviceStatusMaintenanceReadProvider,
    );
    if (maintenance == null) {
      return const SizedBox.shrink();
    }
    final StarLocalizations l10n = StarLocalizations.of(context);
    final bool isMobile = isMobileLayout(context);
    return StarNagbar(
      isMobile: isMobile,
      backgroundColor: maintenanceNagbarBackgroundColor(maintenance),
      textColor: Colors.white,
      dismissible: true,
      onDismiss: () {
        unawaited(
          ref
              .read(scheduledMaintenanceDismissalReadProvider.notifier)
              .dismiss(maintenance),
        );
      },
      child: StarNagbarContent(
        isMobile: isMobile,
        message: maintenanceNagbarMessage(
          context: context,
          maintenance: maintenance,
        ),
        onDismiss: () {
          unawaited(
            ref
                .read(scheduledMaintenanceDismissalReadProvider.notifier)
                .dismiss(maintenance),
          );
        },
        actions: StarNagbarButton(
          isMobile: isMobile,
          label: l10n.nagbarLearnMore,
          onPressed: () => handleExternalLinkTap(context, maintenance.url),
        ),
      ),
    );
  }
}
