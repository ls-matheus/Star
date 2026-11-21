import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:star_app/core/api/sudo_interceptor.dart';
import 'package:star_app/core/talker.dart';
import 'package:star_app/core/theme/star_theme_extension.dart';
import 'package:star_app/features/recovery_kit/domain/recovery_kit.dart';
import 'package:star_app/features/recovery_kit/presentation/recovery_kit_sheet.dart';
import 'package:star_app/features/recovery_kit/providers/recovery_kit_providers.dart';
import 'package:star_app/features/ui/bottom_sheet/star_confirm_sheet.dart';
import 'package:star_app/features/ui/button/star_button.dart';
import 'package:star_app/features/ui/button/star_button_size.dart';
import 'package:star_app/features/ui/settings/star_settings_subsection.dart';
import 'package:star_app/features/ui/toast/star_toast.dart';
import 'package:star_app/features/ui/toast/toast_provider.dart';
import 'package:star_app/features/ui/warning_alert/star_warning_alert.dart';
import 'package:star_app/l10n/generated/star_localizations.dart';
import 'package:star_app/material_ui.dart';
import 'package:star_app/shared/utils/relative_time.dart';
import 'package:star_dart/export.dart';

class RecoveryKitSettingsSubsection extends ConsumerStatefulWidget {
  const RecoveryKitSettingsSubsection({super.key});

  @override
  ConsumerState<RecoveryKitSettingsSubsection> createState() =>
      _RecoveryKitSettingsSubsectionState();
}

class _RecoveryKitSettingsSubsectionState
    extends ConsumerState<RecoveryKitSettingsSubsection> {
  bool _creating = false;

  Future<void> _create({required bool replacing}) async {
    final StarLocalizations l10n = StarLocalizations.of(context);
    if (replacing) {
      final bool? confirmed = await StarConfirmSheet.show(
        context,
        title: l10n.recoveryKitReplaceTitle,
        description: l10n.recoveryKitReplaceDescription,
        confirmLabel: l10n.recoveryKitCreateNew,
      );
      if (confirmed != true || !mounted) {
        return;
      }
    }
    setState(() => _creating = true);
    try {
      final RecoveryKit kit = await ref
          .read(pendingRecoveryKitProvider.notifier)
          .create(
            reason: replacing
                ? RecoveryKitReason.replaced
                : RecoveryKitReason.created,
          );
      if (mounted) {
        await RecoveryKitSheet.show(context, kit);
      }
    } on Exception catch (e) {
      if (isSudoCancellation(e)) {
        return;
      }
      talker.warning('[RecoveryKitSettings] Create failed: $e');
      ref
          .read(toastProvider.notifier)
          .show(
            StarToast(
              message: l10n.recoveryKitCreateFailed,
              variant: StarToastVariant.danger,
            ),
          );
    } finally {
      if (mounted) {
        setState(() => _creating = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final StarLocalizations l10n = StarLocalizations.of(context);
    final AsyncValue<RecoveryKitStatusResponse> status = ref.watch(
      recoveryKitStatusProvider,
    );
    final RecoveryKitStatusResponse? value = status.value;
    final bool hasKit = value?.hasRecoveryKit ?? false;
    final DateTime? createdAt = value?.createdAt;

    return StarSettingsSubsection(
      title: l10n.recoveryKitSectionTitle,
      description: l10n.recoveryKitSectionDescription,
      children: [
        if (value != null && !hasKit)
          StarWarningAlert(message: l10n.recoveryKitNone)
        else if (createdAt != null)
          Text(
            l10n.recoveryKitCreatedRelative(relativeTime(createdAt, l10n)),
            style: context.textStyles.bodySmall,
          ),
        StarButton.primary(
          onPressedAsync: value == null || _creating
              ? null
              : () => _create(replacing: hasKit),
          label: hasKit ? l10n.recoveryKitCreateNew : l10n.recoveryKitCreate,
          isLoading: _creating,
          size: StarButtonSize.small,
        ),
      ],
    );
  }
}
