import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:star_app/core/desktop/notifications/desktop_notification_permission.dart';
import 'package:star_app/core/providers/instance/instance_runtime_config_provider.dart';
import 'package:star_app/core/system_permissions/system_permission_kind.dart';
import 'package:star_app/core/theme/star_theme_extension.dart';
import 'package:star_app/features/ui/button/star_button.dart';
import 'package:star_app/features/ui/modal/star_modal.dart';
import 'package:star_app/l10n/generated/star_localizations.dart';
import 'package:star_app/material_ui.dart';
import 'package:permission_handler/permission_handler.dart';

class SystemPermissionSettingsPrompt {
  SystemPermissionSettingsPrompt._();

  static Future<void> show(
    BuildContext context, {
    required SystemPermissionKind kind,
  }) {
    final StarLocalizations l10n = StarLocalizations.of(context);
    final String productName = ProviderScope.containerOf(
      context,
    ).read(instanceRuntimeConfigProvider).productName;
    return StarModal.show<void>(
      context,
      title: l10n.systemPermissionSettingsTitle,
      centered: true,
      builder: (BuildContext dialogContext, VoidCallback close) {
        final textStyles = dialogContext.textStyles;
        return Text(
          messageForKind(l10n, kind, productName: productName),
          style: textStyles.bodySmall.copyWith(height: 1.4),
          textAlign: TextAlign.center,
        );
      },
      actionsBuilder: (void Function([void]) pop) => <Widget>[
        StarButton.primary(
          onPressed: () async {
            if (kind != SystemPermissionKind.notifications ||
                !await openDesktopNotificationSettings()) {
              await openAppSettings();
            }
            pop();
          },
          label: l10n.systemPermissionSettingsOpenSettings,
        ),
        const SizedBox(height: 8),
        StarButton.secondary(onPressed: () => pop(), label: l10n.cancel),
      ],
    );
  }

  static String messageForKind(
    StarLocalizations l10n,
    SystemPermissionKind kind, {
    required String productName,
  }) {
    switch (kind) {
      case SystemPermissionKind.microphone:
        return l10n.systemPermissionMicrophoneMessage(productName);
      case SystemPermissionKind.camera:
        return l10n.systemPermissionCameraMessage(productName);
      case SystemPermissionKind.photos:
        return l10n.systemPermissionPhotosMessage(productName);
      case SystemPermissionKind.notifications:
        return l10n.systemPermissionNotificationsMessage(productName);
    }
  }
}
