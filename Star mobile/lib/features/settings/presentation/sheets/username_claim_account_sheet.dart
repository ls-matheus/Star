import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:star_app/core/api/dio_error_message.dart';
import 'package:star_app/core/api/star_client_provider.dart';
import 'package:star_app/core/talker.dart';
import 'package:star_app/core/theme/star_theme_extension.dart';
import 'package:star_app/features/recovery_kit/domain/recovery_kit.dart';
import 'package:star_app/features/recovery_kit/providers/recovery_kit_providers.dart';
import 'package:star_app/features/settings/presentation/widgets/wide_settings_content_layout.dart';
import 'package:star_app/features/settings/providers/view_models/user_settings_view_model.dart';
import 'package:star_app/features/settings/utils/replacement_session.dart';
import 'package:star_app/features/ui/button/star_button.dart';
import 'package:star_app/features/ui/input/star_input.dart';
import 'package:star_app/features/ui/toast/star_toast.dart';
import 'package:star_app/features/ui/toast/toast_provider.dart';
import 'package:star_app/l10n/generated/star_localizations.dart';
import 'package:star_app/material_ui.dart';
import 'package:star_dart/export.dart';

Map<String, String> _fieldErrorsFrom(DioException error) {
  final Object? data = error.response?.data;
  final Map<String, String> fieldErrors = <String, String>{};
  if (data is Map<String, dynamic> && data['errors'] is List<dynamic>) {
    for (final Object? item in data['errors'] as List<dynamic>) {
      if (item is! Map<String, dynamic>) {
        continue;
      }
      final Object? field = item['path'] ?? item['field'];
      final Object? message = item['message'];
      if (field is String && message is String && message.isNotEmpty) {
        fieldErrors.putIfAbsent(field, () => message);
      }
    }
  }
  return fieldErrors;
}

class UsernameClaimAccountSheet extends ConsumerStatefulWidget {
  const UsernameClaimAccountSheet({super.key});

  @override
  ConsumerState<UsernameClaimAccountSheet> createState() =>
      _UsernameClaimAccountSheetState();
}

class _UsernameClaimAccountSheetState
    extends ConsumerState<UsernameClaimAccountSheet> {
  late final TextEditingController _usernameController = TextEditingController(
    text: ref.read(userSettingsViewModelProvider).username,
  );
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _loading = false;
  String? _error;
  Map<String, String> _fieldErrors = const <String, String>{};

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _claim() async {
    final l10n = StarLocalizations.of(context);
    final String username = _usernameController.text.trim();
    final String password = _passwordController.text;
    if (username.isEmpty || password.isEmpty) {
      return;
    }
    if (password != _confirmController.text) {
      setState(() {
        _error = null;
        _fieldErrors = <String, String>{'confirm': l10n.resetPasswordMismatch};
      });
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
      _fieldErrors = const <String, String>{};
    });
    try {
      final UserUpdateResponse response = await ref
          .read(starClientProvider)
          .users
          .updateCurrentUser(
            body: UserUpdateWithVerificationRequest(
              username: username,
              newPassword: password,
            ),
          );
      final String? token = response.token;
      final String? authSessionIdHash = response.authSessionIdHash;
      if (token != null && authSessionIdHash != null) {
        await applyReplacementSession(
          ref,
          token: token,
          authSessionIdHash: authSessionIdHash,
        );
      }
      await ref.read(userSettingsViewModelProvider.notifier).loadProfile();
      ref
          .read(toastProvider.notifier)
          .show(
            StarToast(
              message: l10n.claimAccountSuccess,
              variant: StarToastVariant.success,
            ),
          );
      unawaited(
        ref
            .read(pendingRecoveryKitProvider.notifier)
            .createAndPresent(
              reason: RecoveryKitReason.created,
              password: password,
              username: response.username,
              discriminator: response.discriminator,
            )
            .catchError((Object e) {
              talker.warning('[UsernameClaim] Recovery kit failed: $e');
            }),
      );
      if (mounted) {
        Navigator.of(context).pop();
      }
    } on DioException catch (e) {
      if (!mounted) {
        return;
      }
      final Map<String, String> fieldErrors = _fieldErrorsFrom(e);
      setState(() {
        _loading = false;
        _fieldErrors = fieldErrors;
        _error = fieldErrors.isEmpty
            ? userFacingErrorMessage(
                e,
                StarLocalizations.of(context).genericError,
              )
            : null;
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
            l10n.claimAccountUsernameDescription,
            style: context.textStyles.bodySmall.copyWith(
              color: colors.textSecondary,
            ),
          ),
          SizedBox(height: layout.s4),
          StarInput(
            controller: _usernameController,
            label: l10n.usernameLabel,
            autofocus: true,
            autocorrect: false,
            maxLength: 32,
            autofillHints: const [AutofillHints.newUsername],
            textInputAction: TextInputAction.next,
            errorText: _fieldErrors['username'],
          ),
          const SizedBox(height: 12),
          StarInput(
            controller: _passwordController,
            label: l10n.claimAccountPasswordLabel,
            obscureText: true,
            maxLength: 128,
            autofillHints: const [AutofillHints.newPassword],
            textInputAction: TextInputAction.next,
            errorText: _fieldErrors['new_password'] ?? _fieldErrors['password'],
          ),
          const SizedBox(height: 12),
          StarInput(
            controller: _confirmController,
            label: l10n.registerConfirmPassword,
            obscureText: true,
            maxLength: 128,
            autofillHints: const [AutofillHints.newPassword],
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _claim(),
            errorText: _fieldErrors['confirm'],
          ),
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
                  onPressed: _loading ? null : _claim,
                  label: l10n.claimAccount,
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
