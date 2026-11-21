import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:star_app/core/providers/instance/instance_runtime_config_provider.dart';
import 'package:star_app/core/theme/star_theme_extension.dart';
import 'package:star_app/features/settings/utils/platform_desktop_utils.dart';
import 'package:star_app/features/shell/providers/nagbar/push_notification_permission_status_provider.dart';
import 'package:star_app/features/shell/utils/enable_push_notifications.dart';
import 'package:star_app/features/ui/button/star_button.dart';
import 'package:star_app/features/ui/button/star_button_size.dart';
import 'package:star_app/features/ui/warning_alert/star_warning_alert.dart';
import 'package:star_app/l10n/generated/star_localizations.dart';
import 'package:star_app/material_ui.dart';

class UserNotificationsPermissionBanner extends ConsumerWidget {
  const UserNotificationsPermissionBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!isMobileNative) {
      return const SizedBox.shrink();
    }
    final StarLocalizations l10n = StarLocalizations.of(context);
    final layout = context.layout;
    final AsyncValue<bool> permissionGrantedAsync = ref.watch(
      pushNotificationPermissionGrantedProvider,
    );
    final bool requiresSystemSettings = ref
        .watch(pushNotificationRequiresSystemSettingsProvider)
        .maybeWhen(data: (bool value) => value, orElse: () => false);
    return permissionGrantedAsync.when(
      data: (bool granted) {
        if (granted) {
          return const SizedBox.shrink();
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (requiresSystemSettings)
              StarWarningAlert(
                title: l10n.notificationsPermissionDeniedTitle,
                message: l10n.systemPermissionNotificationsMessage(
                  ref.watch(
                    instanceRuntimeConfigProvider.select(
                      (config) => config.productName,
                    ),
                  ),
                ),
              )
            else
              StarWarningAlert(
                variant: StarAlertVariant.info,
                message: l10n.nagbarPushNotification,
              ),
            SizedBox(height: layout.s2),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: StarButton.secondary(
                size: StarButtonSize.small,
                label: requiresSystemSettings
                    ? l10n.nagbarOpenSettings
                    : l10n.nagbarEnableNotifications,
                onPressedAsync: () => enablePushNotifications(
                  context,
                  requiresSystemSettings: requiresSystemSettings,
                ),
              ),
            ),
            SizedBox(height: layout.s3),
          ],
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
    );
  }
}
