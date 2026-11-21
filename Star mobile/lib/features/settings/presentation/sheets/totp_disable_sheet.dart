import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:star_app/core/api/dio_error_message.dart';
import 'package:star_app/core/api/star_client_provider.dart';
import 'package:star_app/core/theme/star_theme_extension.dart';
import 'package:star_app/features/settings/data/disable_totp_mfa.dart';
import 'package:star_app/features/settings/presentation/widgets/wide_settings_content_layout.dart';
import 'package:star_app/features/settings/providers/view_models/user_settings_view_model.dart';
import 'package:star_app/features/ui/bottom_sheet/star_bottom_sheet.dart';
import 'package:star_app/features/ui/button/star_button.dart';
import 'package:star_app/features/ui/input/star_input.dart';
import 'package:star_app/features/ui/toast/star_toast.dart';
import 'package:star_app/features/ui/toast/toast_provider.dart';
import 'package:star_app/l10n/generated/star_localizations.dart';
import 'package:star_app/material_ui.dart';

class TotpDisableSheet extends ConsumerStatefulWidget {
  const TotpDisableSheet({super.key});

  static Future<void> show(BuildContext context, WidgetRef ref) {
    return StarBottomSheet.show<void>(
      context,
      title: StarLocalizations.of(context).totpDisableTitle,
      useRootNavigator: true,
      builder: (_, _) => const TotpDisableSheet(),
    );
  }

  @override
  ConsumerState<TotpDisableSheet> createState() => _TotpDisableSheetState();
}

class _TotpDisableSheetState extends ConsumerState<TotpDisableSheet> {
  final _codeController = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    final code = _codeController.text.replaceAll(' ', '').trim();
    if (code.isEmpty) {
      return;
    }

    final l10n = StarLocalizations.of(context);

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      await disableTotpMfa(dio: ref.read(starDioProvider), code: code);

      ref
          .read(toastProvider.notifier)
          .show(
            StarToast(
              message: l10n.totpDisableSuccess,
              variant: StarToastVariant.success,
            ),
          );

      await ref.read(userSettingsViewModelProvider.notifier).loadProfile();

      if (mounted) {
        Navigator.of(context).pop();
      }
    } on DioException catch (e) {
      setState(() {
        _loading = false;
        _error = userFacingErrorMessage(e, l10n.invalidCode);
      });
    }
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
          Text(
            l10n.totpDisableDescription,
            style: context.textStyles.bodySmall.copyWith(
              color: colors.textSecondary,
            ),
          ),
          SizedBox(height: layout.s4),
          StarInput(
            controller: _codeController,
            label: l10n.totpEnableCodeLabel,
            hint: l10n.totpEnableCodeHint,
            autofocus: true,
            maxLength: 10,
            keyboardType: TextInputType.text,
            autocorrect: false,
            enableSuggestions: false,
            autofillHints: const [AutofillHints.oneTimeCode],
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _handleSubmit(),
            errorText: _error,
          ),
          SizedBox(height: layout.s4),
          Row(
            children: [
              Expanded(
                child: StarButton.secondary(
                  onPressed: _loading
                      ? null
                      : () => Navigator.of(context).pop(),
                  label: l10n.cancel,
                  fitContent: true,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: StarButton.primary(
                  onPressed: _loading ? null : _handleSubmit,
                  label: l10n.continueAction,
                  isLoading: _loading,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
