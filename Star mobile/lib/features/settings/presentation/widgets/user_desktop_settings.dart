import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:star_app/features/settings/presentation/widgets/wide_settings_content_layout.dart';
import 'package:star_app/features/settings/providers/preferences/desktop_behavior_preferences_provider.dart';
import 'package:star_app/features/ui/ui.dart';
import 'package:star_app/l10n/generated/star_localizations.dart';
import 'package:star_app/material_ui.dart';

class UserDesktopSettings extends ConsumerWidget {
  const UserDesktopSettings({super.key, this.scrollController});

  final ScrollController? scrollController;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final StarLocalizations l10n = StarLocalizations.of(context);
    final DesktopBehaviorPreferencesState preferences = ref.watch(
      desktopBehaviorPreferencesProvider,
    );
    final DesktopBehaviorPreferences notifier = ref.read(
      desktopBehaviorPreferencesProvider.notifier,
    );
    final bool isMac = Platform.isMacOS;

    return SingleChildScrollView(
      controller: scrollController,
      padding: settingsScrollPadding(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          StarSettingsSection(
            title: l10n.desktopSettingsWindowSectionTitle,
            isFirst: true,
            children: [
              StarSettingsSwitchItem(
                label: isMac
                    ? l10n.desktopSettingsShowMenuBarIcon
                    : l10n.desktopSettingsShowTrayIcon,
                value: preferences.showTrayIcon,
                onChanged: (value) => notifier.setShowTrayIcon(value: value),
              ),
              StarSettingsSwitchItem(
                label: isMac
                    ? l10n.desktopSettingsMinimizeToMenuBar
                    : l10n.desktopSettingsMinimizeToTray,
                value: preferences.minimizeToTray,
                enabled: preferences.showTrayIcon,
                onChanged: (value) => notifier.setMinimizeToTray(value: value),
              ),
              StarSettingsSwitchItem(
                label: isMac
                    ? l10n.desktopSettingsCloseToMenuBar
                    : l10n.desktopSettingsCloseToTray,
                value: preferences.closeToTray,
                enabled: preferences.showTrayIcon,
                onChanged: (value) => notifier.setCloseToTray(value: value),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
