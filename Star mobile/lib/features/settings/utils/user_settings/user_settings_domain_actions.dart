import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:star_app/features/settings/presentation/sheets/hide_muted_channels_confirm_sheet.dart';
import 'package:star_app/features/settings/providers/view_models/user_settings_view_model.dart';
import 'package:star_app/features/ui/settings/star_settings_confirm_sheet.dart';
import 'package:star_app/l10n/generated/star_localizations.dart';
import 'package:star_app/material_ui.dart';

Future<void> handleTrustAllDomainsChange(
  BuildContext context,
  WidgetRef ref, {
  required bool value,
}) async {
  final notifier = ref.read(userSettingsViewModelProvider.notifier);
  final l10n = StarLocalizations.of(context);

  if (value) {
    final confirmed = await showStarSettingsConfirmSheet(
      context,
      title: l10n.externalLinkTrustAllConfirmTitle,
      description: l10n.externalLinkTrustAllConfirmDescription,
      confirmLabel: l10n.externalLinkTrustAllConfirmAction,
      isDanger: true,
    );
    if (confirmed != true) {
      return;
    }
    await notifier.setTrustAllDomains(trustAll: true);
    return;
  }

  final confirmed = await showStarSettingsConfirmSheet(
    context,
    title: l10n.externalLinkStopTrustingAllTitle,
    description: l10n.externalLinkStopTrustingAllDescription,
    confirmLabel: l10n.externalLinkStopTrustingAllAction,
  );
  if (confirmed != true) {
    return;
  }
  await notifier.setTrustAllDomains(trustAll: false);
}

Future<void> handleDefaultHideMutedChannelsChange(
  BuildContext context,
  WidgetRef ref, {
  required bool value,
}) async {
  final notifier = ref.read(userSettingsViewModelProvider.notifier);
  final choice = await showHideMutedChannelsConfirmSheet(context, value: value);
  if (choice == null) {
    return;
  }

  await notifier.setDefaultHideMutedChannels(value: value);
  if (choice == HideMutedChannelsChoice.applyAll) {
    await notifier.applyDefaultHideMutedChannelsToExistingGuilds(value: value);
  }
}
