import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:star_app/core/api/dio_error_message.dart';
import 'package:star_app/core/api/star_client_provider.dart';
import 'package:star_app/core/api/sudo_interceptor.dart';
import 'package:star_app/core/talker.dart';
import 'package:star_app/core/theme/star_theme_extension.dart';
import 'package:star_app/features/settings/presentation/widgets/wide_settings_content_layout.dart';
import 'package:star_app/features/ui/bottom_sheet/star_bottom_sheet.dart';
import 'package:star_app/features/ui/button/star_button.dart';
import 'package:star_app/features/ui/button/star_button_size.dart';
import 'package:star_app/features/ui/checkbox/star_checkbox.dart';
import 'package:star_app/features/ui/toast/star_toast.dart';
import 'package:star_app/features/ui/toast/toast_provider.dart';
import 'package:star_app/features/ui/warning_alert/star_warning_alert.dart';
import 'package:star_app/l10n/generated/star_localizations.dart';
import 'package:star_app/material_ui.dart';
import 'package:star_app/shared/icons/phosphor.dart';
import 'package:star_app/shared/utils/clipboard_utils.dart';
import 'package:star_dart/export.dart';

class BackupCodesSheet extends ConsumerStatefulWidget {
  const BackupCodesSheet({required this.codes, super.key});

  final List<MfaBackupCodesResponseBackupCodes> codes;

  static Future<void> showWithCodes(
    BuildContext context,
    WidgetRef ref, {
    required List<MfaBackupCodesResponseBackupCodes> codes,
  }) {
    return StarBottomSheet.show<void>(
      context,
      title: StarLocalizations.of(context).backupCodesTitle,
      useRootNavigator: true,
      builder: (_, _) => BackupCodesSheet(codes: codes),
    );
  }

  static Future<void> showView(BuildContext context, WidgetRef ref) async {
    try {
      final client = ref.read(starClientProvider);
      final response = await client.users.getBackupCodesMfa(
        body: const MfaBackupCodesRequest(regenerate: false),
      );

      if (context.mounted) {
        await showWithCodes(context, ref, codes: response.backupCodes);
      }
    } on Exception catch (e) {
      if (isSudoCancellation(e)) {
        return;
      }
      talker.warning('[BackupCodesSheet] Loading backup codes failed: $e');
      if (!context.mounted) {
        return;
      }
      ref
          .read(toastProvider.notifier)
          .show(
            StarToast(
              message: userFacingErrorMessage(
                e,
                StarLocalizations.of(context).recoveryKitBackupCodesFailed,
              ),
              variant: StarToastVariant.danger,
            ),
          );
    }
  }

  @override
  ConsumerState<BackupCodesSheet> createState() => _BackupCodesSheetState();
}

class _BackupCodesSheetState extends ConsumerState<BackupCodesSheet> {
  bool _acknowledged = false;

  void _copyToClipboard() {
    final codesText = widget.codes.map((c) => c.code).join('\n');
    unawaited(
      copyToClipboard(
        context: context,
        value: codesText,
        message: StarLocalizations.of(context).backupCodesCopied,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = StarLocalizations.of(context);
    final colors = context.colors;
    final layout = context.layout;

    return SingleChildScrollView(
      padding: settingsSheetScrollPadding(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          StarWarningAlert(
            variant: StarAlertVariant.danger,
            message: l10n.backupCodesWarning,
          ),
          const SizedBox(height: 20),

          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: widget.codes.map((code) {
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: StarBottomSheet.cardColorOf(context),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  code.code,
                  style: context.textStyles.codeText.copyWith(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: code.consumed
                        ? colors.textPrimaryMuted
                        : colors.textPrimary,
                    decoration: code.consumed
                        ? TextDecoration.lineThrough
                        : TextDecoration.none,
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),

          Row(
            children: [
              StarButton.secondary(
                onPressed: _copyToClipboard,
                label: l10n.backupCodesCopy,
                icon: PhosphorIconsBold.clipboardText,
                size: StarButtonSize.small,
                fitContent: true,
              ),
            ],
          ),
          const SizedBox(height: 24),

          StarCheckbox(
            value: _acknowledged,
            onChanged: (v) => setState(() => _acknowledged = v ?? false),
            label: l10n.backupCodesAcknowledge,
          ),
          SizedBox(height: layout.s4),

          StarButton.primary(
            onPressed: _acknowledged ? () => Navigator.of(context).pop() : null,
            label: l10n.backupCodesDone,
          ),
        ],
      ),
    );
  }
}
