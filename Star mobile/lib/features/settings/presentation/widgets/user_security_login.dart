import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:star_app/core/api/star_client_provider.dart';
import 'package:star_app/core/platform/star_platform.dart';
import 'package:star_app/core/providers/app/account_user_id.dart';
import 'package:star_app/core/providers/instance/instance_runtime_config_provider.dart';
import 'package:star_app/core/theme/star_color_theme.dart';
import 'package:star_app/core/theme/star_theme_extension.dart';
import 'package:star_app/features/recovery_kit/presentation/recovery_kit_settings_section.dart';
import 'package:star_app/features/settings/presentation/sheets/account_delete_sheet.dart';
import 'package:star_app/features/settings/presentation/sheets/account_disable_sheet.dart';
import 'package:star_app/features/settings/presentation/sheets/backup_codes_sheet.dart';
import 'package:star_app/features/settings/presentation/sheets/claim_account_sheet.dart';
import 'package:star_app/features/settings/presentation/sheets/email_change_sheet.dart';
import 'package:star_app/features/settings/presentation/sheets/passkey_name_sheet.dart';
import 'package:star_app/features/settings/presentation/sheets/password_change_sheet.dart';
import 'package:star_app/features/settings/presentation/sheets/totp_disable_sheet.dart';
import 'package:star_app/features/settings/presentation/sheets/totp_enable_sheet.dart';
import 'package:star_app/features/settings/presentation/widgets/app_lock_settings_row.dart';
import 'package:star_app/features/settings/presentation/widgets/wide_settings_content_layout.dart';
import 'package:star_app/features/settings/providers/view_models/user_settings_view_model.dart';
import 'package:star_app/features/settings/providers/view_models/webauthn_credentials_view_model.dart';
import 'package:star_app/features/settings/utils/resend_verification_email.dart';
import 'package:star_app/features/shell/presentation/responsive_layout.dart'
    show isMobileLayout;
import 'package:star_app/features/ui/bottom_sheet/star_bottom_sheet.dart';
import 'package:star_app/features/ui/button/star_button.dart';
import 'package:star_app/features/ui/button/star_button_size.dart';
import 'package:star_app/features/ui/modal/star_modal.dart';
import 'package:star_app/features/ui/settings/star_settings_section.dart';
import 'package:star_app/features/ui/settings/star_settings_subsection.dart';
import 'package:star_app/features/ui/text/star_field_label.dart';
import 'package:star_app/features/ui/text_link/star_text_link.dart';
import 'package:star_app/features/ui/warning_alert/star_warning_alert.dart';
import 'package:star_app/l10n/generated/star_localizations.dart';
import 'package:star_app/material_ui.dart';
import 'package:star_app/shared/icons/phosphor.dart';
import 'package:star_app/shared/utils/api_error_presentation.dart';
import 'package:star_app/shared/utils/relative_time.dart';
import 'package:star_dart/export.dart';

const int _kMaxPasskeys = 10;

class UserSecurityLogin extends ConsumerStatefulWidget {
  const UserSecurityLogin({super.key, this.scrollController});

  final ScrollController? scrollController;

  @override
  ConsumerState<UserSecurityLogin> createState() => _UserSecurityLoginState();
}

class _UserSecurityLoginState extends ConsumerState<UserSecurityLogin> {
  bool _emailRevealed = false;

  String _maskEmail(String email) {
    final atIndex = email.indexOf('@');
    if (atIndex <= 0) {
      return email;
    }
    return '${'*' * atIndex}${email.substring(atIndex)}';
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(userSettingsViewModelProvider);
    final passkeyState = ref.watch(
      webauthnCredentialsViewModelProvider(watchAccountUserId(ref)),
    );
    final colors = context.colors;
    final l10n = StarLocalizations.of(context);

    return SingleChildScrollView(
      controller: widget.scrollController,
      padding: settingsScrollPadding(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          StarSettingsSection(
            sectionId: 'account',
            title: l10n.securityAccountTitle,
            description: l10n.securityAccountDescription,
            isFirst: true,
            children: [
              if (!state.usernameSignIn)
                _buildEmailSection(state, colors, l10n),
              _buildPasswordSection(state, colors, l10n),
              if (state.usernameSignIn && state.isClaimed)
                const RecoveryKitSettingsSubsection(),
            ],
          ),
          StarSettingsSection(
            sectionId: 'security',
            title: l10n.securitySectionTitle,
            description: ref.watch(activeInstanceSupportsPasskeysProvider)
                ? l10n.securitySectionDescription
                : l10n.securitySectionDescriptionNoPasskeys,
            children: [
              _buildSecuritySection(state, passkeyState, colors, l10n),
              if (isStarNativeMobileOs) const AppLockSettingsRow(),
            ],
          ),
          _buildDangerZone(state, colors, l10n),
        ],
      ),
    );
  }

  Widget _buildEmailSection(
    UserSettingsViewState s,
    StarColorTheme colors,
    StarLocalizations l10n,
  ) {
    return StarSettingsSubsection(
      title: l10n.securityLoginEmailSectionTitle,
      description: l10n.securityLoginEmailSectionDescription(
        ref.watch(
          instanceRuntimeConfigProvider.select((config) => config.productName),
        ),
      ),
      children: [
        if (!s.hasVerifiedEmail) ...[
          StarWarningAlert(message: l10n.securityLoginNoEmailSet),
          StarButton.primary(
            onPressedAsync: () => ClaimAccountSheet.show(context, ref),
            label: l10n.securityLoginAddEmail,
            size: StarButtonSize.small,
          ),
        ] else ...[
          _responsiveRow(
            label: l10n.securityLoginEmailAddressLabel,
            detail: _emailRevealed ? s.email! : _maskEmail(s.email!),
            actionLabel: l10n.securityLoginChangeEmail,
            onAction: () => EmailChangeSheet.show(context, ref),
            mobileAccessory: StarTextLink(
              text: _emailRevealed
                  ? l10n.securityLoginHide
                  : l10n.securityLoginReveal,
              onTap: () => setState(() => _emailRevealed = !_emailRevealed),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _emailRevealed ? s.email! : _maskEmail(s.email!),
                  style: context.textStyles.bodySmall,
                ),
                const SizedBox(height: 4),
                StarTextLink(
                  text: _emailRevealed
                      ? l10n.securityLoginHide
                      : l10n.securityLoginReveal,
                  onTap: () => setState(() => _emailRevealed = !_emailRevealed),
                ),
              ],
            ),
            button: StarButton.primary(
              onPressedAsync: () => EmailChangeSheet.show(context, ref),
              label: l10n.securityLoginChangeEmail,
              size: StarButtonSize.small,
            ),
          ),
          if (!s.verified) ...[
            StarWarningAlert(
              variant: StarAlertVariant.info,
              message: l10n.securityVerifyEmailRequired,
            ),
            if (ref.watch(
              instanceRuntimeConfigProvider.select(
                (config) => config.emailsEnabled,
              ),
            ))
              StarButton.primary(
                onPressedAsync:
                    ref.watch(resendVerificationEmailInFlightProvider)
                    ? null
                    : () => resendVerificationEmail(ref, context),
                label: l10n.verificationResendEmail,
                size: StarButtonSize.small,
              ),
          ],
        ],
      ],
    );
  }

  Widget _buildPasswordSection(
    UserSettingsViewState s,
    StarColorTheme colors,
    StarLocalizations l10n,
  ) {
    return StarSettingsSubsection(
      title: l10n.securityLoginPasswordSectionTitle,
      description: l10n.securityLoginPasswordSectionDescription,
      children: [
        if (!s.isClaimed) ...[
          Text(
            l10n.securityLoginNoPasswordSet,
            style: context.textStyles.bodySmall.copyWith(
              color: colors.statusWarning,
            ),
          ),
          StarButton.primary(
            onPressedAsync: () => ClaimAccountSheet.show(context, ref),
            label: l10n.securityLoginSetPassword,
            size: StarButtonSize.small,
          ),
        ] else
          _responsiveRow(
            label: l10n.securityLoginCurrentPasswordLabel,
            detail: _passwordLastChanged(s, l10n),
            actionLabel: l10n.securityLoginChangePassword,
            onAction: () => PasswordChangeSheet.show(context, ref),
            child: Text(
              _passwordLastChanged(s, l10n),
              style: context.textStyles.bodySmall,
            ),
            button: StarButton.primary(
              onPressedAsync: () => PasswordChangeSheet.show(context, ref),
              label: l10n.securityLoginChangePassword,
              size: StarButtonSize.small,
            ),
          ),
      ],
    );
  }

  String _passwordLastChanged(
    UserSettingsViewState s,
    StarLocalizations l10n,
  ) {
    final lc = s.passwordLastChangedAt;
    if (lc == null) {
      return l10n.securityLoginPasswordNeverChanged;
    }
    final date = DateTime.tryParse(lc);
    if (date == null) {
      return l10n.securityLoginPasswordLastChanged(lc);
    }
    return l10n.securityLoginPasswordLastChanged(relativeTime(date, l10n));
  }

  Widget _buildSecuritySection(
    UserSettingsViewState s,
    WebauthnCredentialsViewState passkeyState,
    StarColorTheme colors,
    StarLocalizations l10n,
  ) {
    if (!s.isClaimed) {
      return StarSettingsSubsection(
        title: l10n.securityClaimTitle,
        description: l10n.securityClaimDescription,
        children: [
          StarButton.primary(
            onPressedAsync: () => ClaimAccountSheet.show(context, ref),
            label: l10n.claimAccount,
            size: StarButtonSize.small,
          ),
        ],
      );
    }

    if (!s.isVerified) {
      return StarSettingsSubsection(
        title: l10n.securityTfaSectionTitle,
        description: l10n.securityTfaSectionDescription,
        children: [
          StarWarningAlert(message: l10n.securityVerifyEmailRequired),
        ],
      );
    }

    final layout = context.layout;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTfaSubsection(s, colors, l10n),
        if (ref.watch(activeInstanceSupportsPasskeysProvider)) ...[
          SizedBox(height: isMobileLayout(context) ? layout.s4 : layout.s8),
          _buildPasskeysSubsection(s, passkeyState, colors, l10n),
        ],
      ],
    );
  }

  Widget _buildTfaSubsection(
    UserSettingsViewState s,
    StarColorTheme colors,
    StarLocalizations l10n,
  ) {
    return StarSettingsSubsection(
      title: l10n.securityTfaSectionTitle,
      description: l10n.securityTfaSectionDescription,
      children: [
        _responsiveRow(
          label: l10n.securityTfaAuthenticatorApp,
          detail: s.hasTotpMfa
              ? l10n.securityTfaAuthenticatorEnabled
              : l10n.securityTfaAuthenticatorDisabled,
          actionLabel: s.hasTotpMfa ? l10n.disable : l10n.enable,
          onAction: s.hasTotpMfa
              ? () => TotpDisableSheet.show(context, ref)
              : () => TotpEnableSheet.show(context, ref),
          child: Text(
            s.hasTotpMfa
                ? l10n.securityTfaAuthenticatorEnabled
                : l10n.securityTfaAuthenticatorDisabled,
            style: context.textStyles.bodySmall,
          ),
          button: s.hasTotpMfa
              ? StarButton.dangerPrimary(
                  onPressedAsync: () => TotpDisableSheet.show(context, ref),
                  label: l10n.disable,
                  size: StarButtonSize.small,
                )
              : StarButton.primary(
                  onPressedAsync: () => TotpEnableSheet.show(context, ref),
                  label: l10n.enable,
                  size: StarButtonSize.small,
                ),
        ),
        if (s.hasTotpMfa)
          _responsiveRow(
            label: l10n.securityTfaBackupCodes,
            detail: l10n.securityTfaBackupCodesDescription,
            actionLabel: l10n.securityTfaViewCodes,
            onAction: () => BackupCodesSheet.showView(context, ref),
            child: Text(
              l10n.securityTfaBackupCodesDescription,
              style: context.textStyles.bodySmall,
            ),
            button: StarButton.secondary(
              onPressedAsync: () => BackupCodesSheet.showView(context, ref),
              label: l10n.securityTfaViewCodes,
              size: StarButtonSize.small,
            ),
          ),
      ],
    );
  }

  Widget _buildPasskeysSubsection(
    UserSettingsViewState s,
    WebauthnCredentialsViewState passkeyState,
    StarColorTheme colors,
    StarLocalizations l10n,
  ) {
    final count = passkeyState.credentials.length;

    return StarSettingsSubsection(
      title: l10n.securityPasskeysSectionTitle,
      description: l10n.securityPasskeysSectionDescription,
      children: [
        _responsiveRow(
          label: l10n.securityPasskeysRegistered,
          detail: count == 0
              ? l10n.securityPasskeysNone
              : l10n.securityPasskeysCount(count),
          actionLabel: l10n.securityPasskeysAdd,
          onAction: passkeyState.isLoading || count >= _kMaxPasskeys
              ? null
              : _handleAddPasskey,
          child: Text(
            count == 0
                ? l10n.securityPasskeysNone
                : l10n.securityPasskeysCount(count),
            style: context.textStyles.bodySmall,
          ),
          button: StarButton.primary(
            onPressedAsync: passkeyState.isLoading || count >= _kMaxPasskeys
                ? null
                : _handleAddPasskey,
            label: l10n.securityPasskeysAdd,
            size: StarButtonSize.small,
          ),
        ),
        if (passkeyState.credentials.isNotEmpty)
          ...passkeyState.credentials.map(
            (pk) => _buildPasskeyItem(pk, colors, l10n),
          ),
      ],
    );
  }

  Widget _buildPasskeyItem(
    WebAuthnCredentialResponse pk,
    StarColorTheme colors,
    StarLocalizations l10n,
  ) {
    final createdAt = DateTime.tryParse(pk.createdAt);
    final createdAtLabel = createdAt != null
        ? relativeTime(createdAt, l10n)
        : pk.createdAt;
    final details = StringBuffer(l10n.securityPasskeysAdded(createdAtLabel));
    if (pk.lastUsedAt != null) {
      final lastUsedAt = DateTime.tryParse(pk.lastUsedAt!);
      final lastUsedLabel = lastUsedAt != null
          ? relativeTime(lastUsedAt, l10n)
          : pk.lastUsedAt!;
      details.write(
        ' \u2022 '
        '${l10n.securityPasskeysLastUsed(lastUsedLabel)}',
      );
    }

    final layout = context.layout;

    return Padding(
      padding: EdgeInsets.only(bottom: layout.s3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(pk.name, style: context.textStyles.label),
          SizedBox(height: layout.s1),
          Text(
            details.toString(),
            style: context.textStyles.bodySmall.copyWith(fontSize: 13),
          ),
          SizedBox(height: layout.s2),
          Row(
            children: [
              StarButton.secondary(
                onPressedAsync: () => _handleRenamePasskey(pk),
                label: l10n.securityPasskeysRename,
                size: StarButtonSize.compact,
                fitContent: true,
              ),
              SizedBox(width: layout.s2),
              StarButton.dangerSecondary(
                onPressedAsync: () => _handleDeletePasskey(pk, l10n),
                label: l10n.delete,
                size: StarButtonSize.compact,
                fitContent: true,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _handleAddPasskey() async {
    await PasskeyNameSheet.showForCreate(
      context,
      ref,
      onCreated: () => unawaited(
        ref
            .read(
              webauthnCredentialsViewModelProvider(
                readAccountUserId(ref),
              ).notifier,
            )
            .load(silent: true),
      ),
    );
  }

  Future<void> _handleRenamePasskey(WebAuthnCredentialResponse pk) async {
    await PasskeyNameSheet.showForRename(
      context,
      ref,
      credentialId: pk.id,
      currentName: pk.name,
      onRenamed: () => unawaited(
        ref
            .read(
              webauthnCredentialsViewModelProvider(
                readAccountUserId(ref),
              ).notifier,
            )
            .load(silent: true),
      ),
    );
  }

  Future<void> _handleDeletePasskey(
    WebAuthnCredentialResponse pk,
    StarLocalizations l10n,
  ) async {
    final confirmed = await StarConfirmModal.show(
      context,
      title: l10n.securityPasskeysDeleteTitle,
      description: l10n.securityPasskeysDeleteDescription(pk.name),
      confirmLabel: l10n.securityPasskeysDeleteTitle,
      isDanger: true,
      onConfirm: () {},
    );
    if (confirmed != true) {
      return;
    }

    try {
      final client = ref.read(starClientProvider);
      await client.users.deleteWebauthnCredential(
        credentialId: pk.id,
        body: const SudoVerificationSchema(),
      );
      await ref
          .read(
            webauthnCredentialsViewModelProvider(
              readAccountUserId(ref),
            ).notifier,
          )
          .load(silent: true);
    } on Exception catch (error) {
      if (!mounted) {
        return;
      }
      await showApiError(context, ApiErrorAction.deletePasskey, error);
    }
  }

  Widget _buildDangerZone(
    UserSettingsViewState s,
    StarColorTheme colors,
    StarLocalizations l10n,
  ) {
    return StarSettingsSection(
      sectionId: 'danger_zone',
      title: l10n.dangerZoneSectionTitle,
      description: l10n.dangerZoneSectionDescription,
      children: [
        if (isMobileLayout(context)) ...[
          if (s.isClaimed)
            StarBottomSheetMenuItem(
              label: l10n.dangerZoneDisableTitle,
              hint: l10n.dangerZoneDisableDescription,
              isDanger: true,
              onTap: () => unawaited(AccountDisableSheet.show(context, ref)),
            ),
          StarBottomSheetMenuItem(
            label: l10n.dangerZoneDeleteTitle,
            hint: l10n.dangerZoneDeleteEntryDescription,
            isDanger: true,
            onTap: () => unawaited(AccountDeleteSheet.show(context, ref)),
          ),
        ] else ...[
          if (s.isClaimed)
            StarSettingsSubsection(
              title: l10n.dangerZoneDisableTitle,
              description: l10n.dangerZoneDisableDescription,
              children: [
                StarButton.dangerPrimary(
                  onPressedAsync: () => AccountDisableSheet.show(context, ref),
                  label: l10n.dangerZoneDisableTitle,
                  size: StarButtonSize.small,
                ),
              ],
            ),
          StarSettingsSubsection(
            title: l10n.dangerZoneDeleteTitle,
            description: l10n.dangerZoneDeleteEntryDescription,
            children: [
              StarButton.dangerPrimary(
                onPressedAsync: () => AccountDeleteSheet.show(context, ref),
                label: l10n.dangerZoneDeleteTitle,
                size: StarButtonSize.small,
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _responsiveRow({
    required String label,
    required String detail,
    required String actionLabel,
    required Future<void> Function()? onAction,
    required Widget child,
    required Widget button,
    Widget? mobileAccessory,
  }) {
    if (isMobileLayout(context)) {
      final colors = context.colors;
      final layout = context.layout;
      return StarMenuGroup.ensureGrouped(
        context,
        StarBottomSheetMenuItem(
          label: label,
          hint: detail,
          enabled: onAction != null,
          onTap: () {
            if (onAction != null) {
              unawaited(onAction());
            }
          },
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (mobileAccessory != null) ...[
                mobileAccessory,
                SizedBox(width: layout.s3),
              ],
              Text(
                actionLabel,
                style: context.textStyles.timestamp.copyWith(
                  color: colors.textSecondary,
                ),
              ),
              SizedBox(width: layout.s1),
              PhosphorIcon(
                PhosphorIconsBold.caretRight,
                size: 16,
                color: colors.textSecondary,
              ),
            ],
          ),
        ),
      );
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        final layout = context.layout;

        if (constraints.maxWidth >= 500) {
          return Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    StarFieldLabel(label),
                    SizedBox(height: layout.s1),
                    child,
                  ],
                ),
              ),
              SizedBox(width: layout.s4),
              button,
            ],
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            StarFieldLabel(label),
            SizedBox(height: layout.s1),
            child,
            SizedBox(height: layout.s3),
            button,
          ],
        );
      },
    );
  }
}
