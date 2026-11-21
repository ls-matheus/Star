import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:star_app/features/settings/providers/preferences/appearance_preferences_provider.dart';
import 'package:star_app/features/ui/ui.dart';
import 'package:star_app/l10n/generated/star_localizations.dart';
import 'package:star_app/material_ui.dart';

class UserAccessibilityKeyboardSection extends ConsumerWidget {
  const UserAccessibilityKeyboardSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = StarLocalizations.of(context);
    final appearance = ref.watch(appearancePreferencesProvider);
    final appearanceNotifier = ref.read(appearancePreferencesProvider.notifier);

    return StarSettingsSection(
      sectionId: 'keyboard',
      title: l10n.accessibilityKeyboardGroupTitle,
      children: [
        StarSettingsSwitchGroup(
          children: [
            StarSettingsSwitchItem.grouped(
              label: l10n.accessibilityShowTextareaFocusRingLabel,
              value: appearance.showTextareaFocusRing,
              onChanged: (value) => unawaited(
                appearanceNotifier.setShowTextareaFocusRing(value: value),
              ),
            ),
            StarSettingsSwitchItem.grouped(
              label: l10n.accessibilityEscapeExitsKeyboardModeLabel,
              value: appearance.escapeExitsKeyboardMode,
              onChanged: (value) => unawaited(
                appearanceNotifier.setEscapeExitsKeyboardMode(value: value),
              ),
            ),
            StarSettingsSwitchItem.grouped(
              label: l10n.accessibilityShowContextMenuShortcutsLabel,
              value: appearance.showContextMenuShortcuts,
              onChanged: (value) => unawaited(
                appearanceNotifier.setShowContextMenuShortcuts(value: value),
              ),
            ),
            StarSettingsSwitchItem.grouped(
              label: l10n.accessibilityConfirmBeforeStartingCallsLabel,
              value: appearance.confirmBeforeStartingCalls,
              onChanged: (value) => unawaited(
                appearanceNotifier.setConfirmBeforeStartingCalls(value: value),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
