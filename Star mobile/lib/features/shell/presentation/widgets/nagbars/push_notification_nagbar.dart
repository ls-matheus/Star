import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:star_app/features/shell/presentation/responsive_layout.dart';
import 'package:star_app/features/shell/presentation/widgets/nagbars/nagbar_widget.dart';
import 'package:star_app/features/shell/providers/nagbar/nagbar_providers.dart';
import 'package:star_app/features/shell/providers/nagbar/push_notification_permission_status_provider.dart';
import 'package:star_app/features/shell/utils/enable_push_notifications.dart';
import 'package:star_app/features/ui/nagbar/star_nagbar.dart';
import 'package:star_app/features/ui/nagbar/star_nagbar_button.dart';
import 'package:star_app/features/ui/nagbar/star_nagbar_content.dart';
import 'package:star_app/l10n/generated/star_localizations.dart';
import 'package:star_app/material_ui.dart';

class PushNotificationNagbar extends ConsumerWidget implements NagbarWidget {
  const PushNotificationNagbar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final StarLocalizations l10n = StarLocalizations.of(context);
    final bool isMobile = isMobileLayout(context);
    final bool requiresSystemSettings = ref
        .watch(pushNotificationRequiresSystemSettingsProvider)
        .maybeWhen(data: (bool value) => value, orElse: () => false);
    return StarNagbar(
      isMobile: isMobile,
      backgroundColor: const Color(0xFF2563EB),
      textColor: Colors.white,
      dismissible: true,
      onDismiss: () =>
          ref.read(nagbarDismissalsProvider.notifier).dismissPushNotification(),
      child: StarNagbarContent(
        isMobile: isMobile,
        message: l10n.nagbarPushNotification,
        onDismiss: () => ref
            .read(nagbarDismissalsProvider.notifier)
            .dismissPushNotification(),
        actions: StarNagbarButton(
          isMobile: isMobile,
          label: requiresSystemSettings
              ? l10n.nagbarOpenSettings
              : l10n.nagbarEnableNotifications,
          onPressed: () => enablePushNotifications(
            context,
            requiresSystemSettings: requiresSystemSettings,
          ),
        ),
      ),
    );
  }
}
