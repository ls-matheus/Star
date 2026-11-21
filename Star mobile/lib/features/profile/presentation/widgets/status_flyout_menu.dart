import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:star_app/core/theme/star_theme_extension.dart';
import 'package:star_app/features/profile/domain/presence_status_labels.dart';
import 'package:star_app/features/profile/domain/time_window_presets.dart';
import 'package:star_app/features/profile/presentation/sheets/status_change_sheet.dart';
import 'package:star_app/features/profile/providers/user_status_service.dart';
import 'package:star_app/features/settings/providers/view_models/user_settings_view_model.dart';
import 'package:star_app/features/ui/desktop_surface/star_desktop_surface.dart';
import 'package:star_app/features/ui/status_indicator/star_status_indicator.dart';
import 'package:star_app/l10n/generated/star_localizations.dart';
import 'package:star_app/material_ui.dart';
import 'package:star_app/shared/icons/phosphor.dart';

const double kStatusExpiryFlyoutWidth = 220;

class StatusFlyoutMenu extends ConsumerWidget {
  const StatusFlyoutMenu({required this.onClose, super.key});

  final VoidCallback onClose;

  void _select(WidgetRef ref, PresenceStatus status, {Duration? duration}) {
    onClose();
    unawaited(
      ref
          .read(userStatusServiceProvider)
          .setPresenceStatus(status: status, duration: duration)
          .catchError((Object _) {}),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final StarLocalizations l10n = StarLocalizations.of(context);
    final List<TimeWindowPreset> expiryPresets = getTimeWindowPresets(
      includeDeveloperOptions: ref
          .watch(userSettingsViewModelProvider)
          .developerMode,
    );
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        for (final PresenceStatus status in kSelectablePresenceStatuses)
          _buildRow(context, ref, l10n, status, expiryPresets),
      ],
    );
  }

  Widget _buildRow(
    BuildContext context,
    WidgetRef ref,
    StarLocalizations l10n,
    PresenceStatus status,
    List<TimeWindowPreset> expiryPresets,
  ) {
    final String statusValue = status.json ?? 'online';
    final bool hasExpiryOptions = status != PresenceStatus.online;
    final Widget row = StarDesktopMenuRow(
      label: presenceStatusLabel(statusValue, l10n),
      hint: presenceStatusDescription(statusValue, l10n),
      hintColor: context.colors.textTertiary,
      crossAxisAlignment: CrossAxisAlignment.start,
      leading: Padding(
        padding: const EdgeInsets.only(top: 1),
        child: SizedBox.square(
          dimension: 18,
          child: Center(
            child: StarStatusIndicator(status: statusValue, size: 14),
          ),
        ),
      ),
      trailing: hasExpiryOptions
          ? Padding(
              padding: const EdgeInsets.only(top: 2),
              child: SizedBox.square(
                dimension: 16,
                child: Center(
                  child: PhosphorIcon(
                    PhosphorIconsBold.caretRight,
                    size: kStarDesktopMenuCaretSize,
                    color: context.colors.textSecondary,
                  ),
                ),
              ),
            )
          : null,
      onTap: () => _select(ref, status),
    );
    if (!hasExpiryOptions) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 1),
        child: row,
      );
    }
    return StarDesktopHoverFlyout(
      width: kStatusExpiryFlyoutWidth,
      flyoutBuilder: (BuildContext flyoutContext) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          for (final TimeWindowPreset preset in expiryPresets)
            StarDesktopMenuRow(
              label: statusExpiryLabel(preset.key, l10n),
              onTap: () => _select(
                ref,
                status,
                duration: minutesToDuration(preset.minutes),
              ),
            ),
        ],
      ),
      child: row,
    );
  }
}
