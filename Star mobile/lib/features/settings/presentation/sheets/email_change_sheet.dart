import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:star_app/core/api/dio_error_message.dart';
import 'package:star_app/core/api/star_client_provider.dart';
import 'package:star_app/core/theme/star_theme_extension.dart';
import 'package:star_app/features/settings/presentation/sheets/resend_timer_mixin.dart';
import 'package:star_app/features/settings/presentation/widgets/wide_settings_content_layout.dart';
import 'package:star_app/features/settings/providers/view_models/user_settings_view_model.dart';
import 'package:star_app/features/ui/bottom_sheet/star_bottom_sheet.dart';
import 'package:star_app/features/ui/button/star_button.dart';
import 'package:star_app/features/ui/button/star_button_size.dart';
import 'package:star_app/features/ui/input/star_input.dart';
import 'package:star_app/features/ui/toast/star_toast.dart';
import 'package:star_app/features/ui/toast/toast_provider.dart';
import 'package:star_app/l10n/generated/star_localizations.dart';
import 'package:star_app/material_ui.dart';
import 'package:star_dart/export.dart';

enum _Stage { intro, verifyOriginal, newEmail, verifyNew }

class EmailChangeSheet extends ConsumerStatefulWidget {
  const EmailChangeSheet({super.key});

  static Future<void> show(BuildContext context, WidgetRef ref) {
    return StarBottomSheet.show<void>(
      context,
      title: StarLocalizations.of(context).emailChangeTitle,
      useRootNavigator: true,
      builder: (_, _) => const EmailChangeSheet(),
    );
  }

  @override
  ConsumerState<EmailChangeSheet> createState() => _EmailChangeSheetState();
}

class _EmailChangeSheetState extends ConsumerState<EmailChangeSheet>
    with ResendTimerMixin {
  _Stage _stage = _Stage.intro;
  bool _loading = false;
  String? _error;

  String? _ticket;
  String? _originalProof;
  bool _requireOriginal = false;

  final _originalCodeController = TextEditingController();
  final _newEmailController = TextEditingController();
  final _newCodeController = TextEditingController();

  @override
  void dispose() {
    _originalCodeController.dispose();
    _newEmailController.dispose();
    _newCodeController.dispose();
    disposeResendTimer();
    super.dispose();
  }

  String _extractErrorMessage(DioException e) {
    return userFacingErrorMessage(
      e,
      StarLocalizations.of(context).genericError,
    );
  }

  Future<void> _handleStart() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final client = ref.read(starClientProvider);
      final response = await client.users.startEmailChange(
        body: const EmptyBodyRequest(),
      );

      _ticket = response.ticket;
      _requireOriginal = response.requireOriginal;
      _originalProof = response.originalProof;

      if (_requireOriginal) {
        startResendTimer(response.resendAvailableAt);
        setState(() {
          _stage = _Stage.verifyOriginal;
          _loading = false;
        });
      } else {
        setState(() {
          _stage = _Stage.newEmail;
          _loading = false;
        });
      }
    } on DioException catch (e) {
      setState(() {
        _loading = false;
        _error = _extractErrorMessage(e);
      });
    }
  }

  Future<void> _handleVerifyOriginal() async {
    final code = _originalCodeController.text.trim();
    if (code.isEmpty || _ticket == null) {
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final client = ref.read(starClientProvider);
      final response = await client.users.verifyOriginalEmailAddress(
        body: EmailChangeVerifyOriginalRequest(ticket: _ticket!, code: code),
      );

      _originalProof = response.originalProof;

      if (!mounted) {
        return;
      }
      setState(() {
        _stage = _Stage.newEmail;
        _loading = false;
      });
    } on DioException catch (e) {
      if (!mounted) {
        return;
      }
      final l10n = StarLocalizations.of(context);
      setState(() {
        _loading = false;
        _error = e.response?.statusCode == 400
            ? l10n.emailChangeInvalidCode
            : _extractErrorMessage(e);
      });
    }
  }

  Future<void> _handleResendOriginalCode() async {
    if (resendCountdown > 0 || _ticket == null) {
      return;
    }

    try {
      final client = ref.read(starClientProvider);
      await client.users.resendOriginalEmailConfirmation(
        body: EmailChangeTicketRequest(ticket: _ticket!),
      );
      startResendTimer(null);
    } on DioException catch (e) {
      setState(() => _error = _extractErrorMessage(e));
    }
  }

  Future<void> _handleSubmitNewEmail() async {
    final newEmail = _newEmailController.text.trim();
    if (newEmail.isEmpty || _ticket == null || _originalProof == null) {
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final client = ref.read(starClientProvider);
      final response = await client.users.requestNewEmailAddress(
        body: EmailChangeRequestNewRequest(
          ticket: _ticket!,
          newEmail: newEmail,
          originalProof: _originalProof!,
        ),
      );

      _ticket = response.ticket;
      startResendTimer(response.resendAvailableAt);

      if (!mounted) {
        return;
      }
      setState(() {
        _stage = _Stage.verifyNew;
        _loading = false;
      });
    } on DioException catch (e) {
      setState(() {
        _loading = false;
        _error = _extractErrorMessage(e);
      });
    }
  }

  Future<void> _handleVerifyNewEmail() async {
    final code = _newCodeController.text.trim();
    if (code.isEmpty || _ticket == null || _originalProof == null) {
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final client = ref.read(starClientProvider);
      final tokenResponse = await client.users.verifyNewEmailAddress(
        body: EmailChangeVerifyNewRequest(
          ticket: _ticket!,
          code: code,
          originalProof: _originalProof!,
        ),
      );

      await client.users.updateCurrentUser(
        body: UserUpdateWithVerificationRequest(
          emailToken: tokenResponse.emailToken,
        ),
      );

      if (!mounted) {
        return;
      }
      final l10n = StarLocalizations.of(context);
      ref
          .read(toastProvider.notifier)
          .show(
            StarToast(
              message: l10n.emailChangeSuccess,
              variant: StarToastVariant.success,
            ),
          );

      await ref.read(userSettingsViewModelProvider.notifier).loadProfile();

      if (mounted) {
        Navigator.of(context).pop();
      }
    } on DioException catch (e) {
      if (!mounted) {
        return;
      }
      final l10n = StarLocalizations.of(context);
      setState(() {
        _loading = false;
        _error = e.response?.statusCode == 400
            ? l10n.emailChangeInvalidCode
            : _extractErrorMessage(e);
      });
    }
  }

  Future<void> _handleResendNewCode() async {
    if (resendCountdown > 0 || _ticket == null) {
      return;
    }

    try {
      final client = ref.read(starClientProvider);
      await client.users.resendNewEmailConfirmation(
        body: EmailChangeTicketRequest(ticket: _ticket!),
      );
      startResendTimer(null);
    } on DioException catch (e) {
      setState(() => _error = _extractErrorMessage(e));
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
          if (_stage != _Stage.intro) ...[
            Text(
              _stageTitle(l10n),
              style: context.textStyles.bodyMedium.copyWith(
                color: colors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: layout.s2),
          ],
          Text(
            _stageDescription(l10n),
            style: context.textStyles.bodySmall.copyWith(
              color: colors.textSecondary,
            ),
          ),
          SizedBox(height: layout.s4),
          ..._buildStageContent(l10n),
          if (_error != null) ...[
            SizedBox(height: layout.s3),
            Text(
              _error!,
              style: context.textStyles.bodySmall.copyWith(
                color: colors.statusDanger,
              ),
            ),
          ],
          SizedBox(height: layout.s4),
          _buildStageAction(l10n),
        ],
      ),
    );
  }

  String _stageTitle(StarLocalizations l10n) {
    switch (_stage) {
      case _Stage.intro:
        return l10n.emailChangeTitle;
      case _Stage.verifyOriginal:
        return l10n.emailChangeVerifyOriginalTitle;
      case _Stage.newEmail:
        return l10n.emailChangeNewEmailTitle;
      case _Stage.verifyNew:
        return l10n.emailChangeVerifyNewTitle;
    }
  }

  String _stageDescription(StarLocalizations l10n) {
    switch (_stage) {
      case _Stage.intro:
        return l10n.emailChangeIntroDescription;
      case _Stage.verifyOriginal:
        return l10n.emailChangeVerifyOriginalDescription;
      case _Stage.newEmail:
        return l10n.emailChangeNewEmailDescription;
      case _Stage.verifyNew:
        return l10n.emailChangeVerifyNewDescription;
    }
  }

  List<Widget> _buildStageContent(StarLocalizations l10n) {
    switch (_stage) {
      case _Stage.intro:
        return const [];
      case _Stage.verifyOriginal:
        return [
          StarInput(
            controller: _originalCodeController,
            label: l10n.verificationCode,
            hint: 'XXXX-XXXX',
            autofocus: true,
            maxLength: 9,
            keyboardType: TextInputType.text,
            autofillHints: const [AutofillHints.oneTimeCode],
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _handleVerifyOriginal(),
          ),
        ];
      case _Stage.newEmail:
        return [
          StarInput(
            controller: _newEmailController,
            label: l10n.emailChangeNewEmailLabel,
            autofocus: true,
            maxLength: 256,
            keyboardType: TextInputType.emailAddress,
            autofillHints: const [AutofillHints.email],
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _handleSubmitNewEmail(),
          ),
        ];
      case _Stage.verifyNew:
        return [
          StarInput(
            controller: _newCodeController,
            label: l10n.verificationCode,
            hint: 'XXXX-XXXX',
            autofocus: true,
            maxLength: 9,
            keyboardType: TextInputType.text,
            autofillHints: const [AutofillHints.oneTimeCode],
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _handleVerifyNewEmail(),
          ),
        ];
    }
  }

  Widget _buildStageAction(StarLocalizations l10n) {
    switch (_stage) {
      case _Stage.intro:
        return StarButton.primary(
          onPressed: _loading ? null : _handleStart,
          label: l10n.emailChangeStart,
          isLoading: _loading,
        );
      case _Stage.verifyOriginal:
        return Row(
          children: [
            Expanded(
              child: StarButton.primary(
                onPressed: _loading ? null : _handleVerifyOriginal,
                label: l10n.verify,
                isLoading: _loading,
              ),
            ),
            const SizedBox(width: 8),
            StarButton.ghost(
              onPressed: resendCountdown > 0 ? null : _handleResendOriginalCode,
              label: resendCountdown > 0
                  ? l10n.resendCountdown(resendCountdown)
                  : l10n.resend,
              size: StarButtonSize.small,
            ),
          ],
        );
      case _Stage.newEmail:
        return StarButton.primary(
          onPressed: _loading ? null : _handleSubmitNewEmail,
          label: l10n.emailChangeNewEmailSubmit,
          isLoading: _loading,
        );
      case _Stage.verifyNew:
        return Row(
          children: [
            Expanded(
              child: StarButton.primary(
                onPressed: _loading ? null : _handleVerifyNewEmail,
                label: l10n.verify,
                isLoading: _loading,
              ),
            ),
            const SizedBox(width: 8),
            StarButton.ghost(
              onPressed: resendCountdown > 0 ? null : _handleResendNewCode,
              label: resendCountdown > 0
                  ? l10n.resendCountdown(resendCountdown)
                  : l10n.resend,
              size: StarButtonSize.small,
            ),
          ],
        );
    }
  }
}
