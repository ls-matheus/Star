import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:star_app/core/api/dio_error_message.dart';
import 'package:star_app/core/build/app_build_config.dart';
import 'package:star_app/core/providers/app/account_user_id.dart';
import 'package:star_app/core/providers/instance/instance_runtime_config_provider.dart';
import 'package:star_app/core/theme/star_color_theme.dart';
import 'package:star_app/core/theme/star_theme_extension.dart';
import 'package:star_app/features/settings/presentation/widgets/wide_settings_content_layout.dart';
import 'package:star_app/features/settings/providers/view_models/connections_view_model.dart';
import 'package:star_app/features/ui/bottom_sheet/star_bottom_sheet.dart';
import 'package:star_app/features/ui/button/star_button.dart';
import 'package:star_app/features/ui/button/star_button_size.dart';
import 'package:star_app/features/ui/input/star_input.dart';
import 'package:star_app/features/ui/select/star_select.dart';
import 'package:star_app/features/ui/tappable/star_tappable.dart';
import 'package:star_app/features/ui/toast/star_toast.dart';
import 'package:star_app/features/ui/toast/toast_provider.dart';
import 'package:star_app/features/ui/warning_alert/star_warning_alert.dart';
import 'package:star_app/l10n/generated/star_localizations.dart';
import 'package:star_app/material_ui.dart';
import 'package:star_app/shared/icons/phosphor.dart';
import 'package:star_app/shared/utils/clipboard_utils.dart';
import 'package:star_dart/export.dart';
import 'package:url_launcher/url_launcher.dart';

enum _AddStep { initiate, verify }

typedef _ConnectionChoice = ({ConnectionType type, String? providerId});

const _ConnectionChoice _blueskyChoice = (
  type: ConnectionType.bluesky,
  providerId: null,
);
const _ConnectionChoice _domainChoice = (
  type: ConnectionType.domain,
  providerId: null,
);

_ConnectionChoice _providerChoice(String providerId) =>
    (type: ConnectionType.oauth, providerId: providerId);

class ConnectionAddSheet {
  const ConnectionAddSheet._();

  static Future<void> _show(
    BuildContext context,
    WidgetRef ref, {
    _ConnectionChoice? defaultChoice,
  }) {
    final l10n = StarLocalizations.of(context);
    final config = ref.read(instanceRuntimeConfigProvider);
    final blueskyEnabled =
        AppBuildConfig.isBlueskyEnabled && config.blueskyEnabled;
    final providers = config.connectionProviders;
    final _ConnectionChoice fallback = blueskyEnabled
        ? _blueskyChoice
        : providers.isNotEmpty
        ? _providerChoice(providers.first.id)
        : _domainChoice;
    final bool defaultAvailable = switch (defaultChoice?.type) {
      null => false,
      ConnectionType.bluesky => blueskyEnabled,
      ConnectionType.oauth => providers.any(
        (provider) => provider.id == defaultChoice!.providerId,
      ),
      _ => true,
    };
    return StarBottomSheet.show<void>(
      context,
      title: l10n.connectionAddTitle,
      useRootNavigator: true,
      builder: (sheetContext, close) => _ConnectionAddBody(
        initialChoice: defaultAvailable ? defaultChoice! : fallback,
        blueskyEnabled: blueskyEnabled,
        providers: providers,
        close: close,
      ),
    );
  }

  static Future<void> showForBluesky(BuildContext context, WidgetRef ref) =>
      _show(context, ref, defaultChoice: _blueskyChoice);

  static Future<void> showForDomain(BuildContext context, WidgetRef ref) =>
      _show(context, ref, defaultChoice: _domainChoice);

  static Future<void> showForProvider(
    BuildContext context,
    WidgetRef ref,
    String providerId,
  ) => _show(context, ref, defaultChoice: _providerChoice(providerId));
}

class _ConnectionAddBody extends ConsumerStatefulWidget {
  const _ConnectionAddBody({
    required this.initialChoice,
    required this.blueskyEnabled,
    required this.providers,
    required this.close,
  });

  final _ConnectionChoice initialChoice;
  final bool blueskyEnabled;
  final List<InstanceConnectionProviderSchema> providers;
  final VoidCallback close;

  @override
  ConsumerState<_ConnectionAddBody> createState() => _ConnectionAddBodyState();
}

class _ConnectionAddBodyState extends ConsumerState<_ConnectionAddBody> {
  late _ConnectionChoice _choice = widget.initialChoice;
  _AddStep _step = _AddStep.initiate;
  final TextEditingController _identifierCtrl = TextEditingController();
  TextEditingController? _hostCtrl;
  TextEditingController? _valueCtrl;

  String? _error;
  ConnectionVerificationResponse? _verification;
  bool _hostCopied = false;
  bool _valueCopied = false;

  @override
  void dispose() {
    _identifierCtrl.dispose();
    _hostCtrl?.dispose();
    _valueCtrl?.dispose();
    super.dispose();
  }

  void _setVerification(ConnectionVerificationResponse v) {
    _hostCtrl?.dispose();
    _valueCtrl?.dispose();
    _hostCtrl = TextEditingController(text: '_star.${v.id}');
    _valueCtrl = TextEditingController(text: 'star-verification=${v.token}');
    setState(() {
      _verification = v;
      _step = _AddStep.verify;
      _error = null;
    });
  }

  void _returnToInitiateStep() {
    setState(() {
      _step = _AddStep.initiate;
      _error = null;
    });
  }

  void _handleSystemBack() {
    switch (_step) {
      case _AddStep.verify:
        _returnToInitiateStep();
      case _AddStep.initiate:
        widget.close();
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, _) {
        if (!didPop) {
          _handleSystemBack();
        }
      },
      child: Padding(
        padding: settingsSheetScrollPadding(context),
        child: _step == _AddStep.initiate ? _buildInitiate() : _buildVerify(),
      ),
    );
  }

  bool get _isBluesky => _choice.type == ConnectionType.bluesky;

  InstanceConnectionProviderSchema? get _provider => widget.providers
      .where((provider) => provider.id == _choice.providerId)
      .firstOrNull;

  Widget _buildInitiate() {
    final l10n = StarLocalizations.of(context);
    final layout = context.layout;
    final provider = _provider;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        StarSelect<_ConnectionChoice>(
          label: l10n.connectionTypeLabel,
          items: [
            if (widget.blueskyEnabled)
              StarSelectItem(
                value: _blueskyChoice,
                label: l10n.connectionsAddBluesky,
              ),
            for (final candidate in widget.providers)
              StarSelectItem(
                value: _providerChoice(candidate.id),
                label: candidate.name,
              ),
            StarSelectItem(
              value: _domainChoice,
              label: l10n.connectionsAddDomain,
            ),
          ],
          value: _choice,
          onChanged: (choice) {
            setState(() {
              _choice = choice;
              _error = null;
            });
          },
        ),
        SizedBox(height: layout.s3),
        if (provider != null) ...[
          Text(
            l10n.connectionProviderInstructions(provider.name),
            style: context.textStyles.bodySmall.copyWith(
              color: context.colors.textSecondary,
            ),
          ),
          if (_error != null) ...[
            SizedBox(height: layout.s3),
            StarWarningAlert(
              message: _error!,
              variant: StarAlertVariant.danger,
            ),
          ],
        ] else
          StarInput(
            controller: _identifierCtrl,
            label: _isBluesky
                ? l10n.connectionHandleLabel
                : l10n.connectionDomainLabel,
            hint: _isBluesky
                ? l10n.connectionHandlePlaceholder
                : l10n.connectionDomainPlaceholder,
            autofocus: true,
            errorText: _error,
          ),
        SizedBox(height: layout.s4),
        StarButton.primary(
          label: provider != null
              ? l10n.connectionConnectWithProvider(provider.name)
              : _isBluesky
              ? l10n.connectionConnectBluesky
              : l10n.connectionContinue,
          onPressedAsync: provider != null
              ? () => _onConnectProvider(provider)
              : _onContinue,
        ),
      ],
    );
  }

  Future<void> _onConnectProvider(
    InstanceConnectionProviderSchema provider,
  ) async {
    final l10n = StarLocalizations.of(context);
    setState(() => _error = null);
    final vm = ref.read(
      connectionsViewModelProvider(readAccountUserId(ref)).notifier,
    );
    final failure = l10n.connectionProviderAuthorizeFailed(provider.name);
    try {
      final url = await vm.authorizeOAuth(provider.id);
      final launched = await launchUrl(
        Uri.parse(url),
        mode: LaunchMode.externalApplication,
      );
      if (!mounted) {
        return;
      }
      if (!launched) {
        setState(() => _error = failure);
        return;
      }
      widget.close();
    } on Object catch (e) {
      if (mounted) {
        setState(() => _error = userFacingErrorMessage(e, failure));
      }
    }
  }

  Future<void> _onContinue() async {
    final l10n = StarLocalizations.of(context);
    var identifier = _identifierCtrl.text.trim();
    if (_isBluesky) {
      identifier = identifier
          .replaceFirst(
            RegExp(r'^https?://bsky\.app/profile/', caseSensitive: false),
            '',
          )
          .replaceFirst(RegExp('^@'), '')
          .toLowerCase();
    } else {
      identifier = identifier
          .replaceFirst(RegExp('^https?://', caseSensitive: false), '')
          .replaceFirst(RegExp(r'/+$'), '')
          .toLowerCase();
    }
    if (identifier.isEmpty) {
      setState(
        () => _error = _isBluesky
            ? l10n.connectionEnterHandle
            : l10n.connectionEnterDomain,
      );
      return;
    }
    final existing = ref
        .read(connectionsViewModelProvider(readAccountUserId(ref)))
        .connections;
    final sdkType = _choice.type;
    final isDuplicate = existing.any(
      (c) => c.type == sdkType && c.name.toLowerCase() == identifier,
    );
    if (isDuplicate) {
      setState(() => _error = l10n.connectionAlreadyExists);
      return;
    }

    final vm = ref.read(
      connectionsViewModelProvider(readAccountUserId(ref)).notifier,
    );
    setState(() => _error = null);

    if (_isBluesky) {
      try {
        final url = await vm.authorizeBluesky(identifier);
        final launched = await launchUrl(
          Uri.parse(url),
          mode: LaunchMode.externalApplication,
        );
        if (!launched) {
          setState(() => _error = l10n.connectionBlueskyAuthorizeFailed);
          return;
        }
        if (mounted) {
          widget.close();
        }
      } on Object catch (e) {
        setState(
          () => _error = userFacingErrorMessage(
            e,
            l10n.connectionBlueskyAuthorizeFailed,
          ),
        );
      }
      return;
    }

    try {
      final data = await vm.initiate(
        type: ConnectionType.domain.toJson(),
        identifier: identifier,
      );
      _setVerification(data);
    } on Object catch (e) {
      setState(
        () => _error = userFacingErrorMessage(e, l10n.connectionInitiateFailed),
      );
    }
  }

  String get _dnsUrl => _verification == null
      ? ''
      : 'https://${_verification!.id}/.well-known/star-verification';

  Widget _buildVerify() {
    final l10n = StarLocalizations.of(context);
    final layout = context.layout;
    final colors = context.colors;
    final textStyles = context.textStyles;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            StarTappable(
              onTap: _returnToInitiateStep,
              builder: (context, _) => Container(
                padding: EdgeInsets.all(layout.s2),
                child: PhosphorIcon(
                  PhosphorIconsBold.caretLeft,
                  size: 20,
                  color: colors.textPrimary,
                ),
              ),
            ),
            SizedBox(width: layout.s2),
            Text(
              l10n.connectionVerifyTitle,
              style: textStyles.heading.copyWith(color: colors.textPrimary),
            ),
          ],
        ),
        SizedBox(height: layout.s3),
        Text(
          l10n.connectionVerifyInstructions,
          style: textStyles.bodySmall.copyWith(color: colors.textSecondary),
        ),
        SizedBox(height: layout.s4),
        if (_error != null) ...[
          StarWarningAlert(
            message: _error!,
            variant: StarAlertVariant.danger,
          ),
          SizedBox(height: layout.s3),
        ],
        _buildDnsCard(),
        SizedBox(height: layout.s4),
        _buildTokenCard(),
        SizedBox(height: layout.s4),
        Row(
          children: [
            Expanded(
              child: StarButton.secondary(
                label: l10n.connectionBack,
                onPressed: _returnToInitiateStep,
                fitContent: true,
              ),
            ),
            SizedBox(width: layout.s2),
            Expanded(
              child: StarButton.primary(
                label: l10n.connectionVerifyButton,
                onPressedAsync: _onVerify,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDnsCard() {
    final l10n = StarLocalizations.of(context);
    final layout = context.layout;
    final colors = context.colors;
    final textStyles = context.textStyles;

    return Container(
      padding: EdgeInsets.all(layout.s3),
      decoration: BoxDecoration(
        color: StarBottomSheet.cardColorOf(context),
        border: Border.all(color: colors.backgroundModifierAccent),
        borderRadius: layout.radiusMd,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.connectionDnsRecordTitle,
            style: textStyles.label.copyWith(color: colors.textPrimary),
          ),
          SizedBox(height: layout.s3),
          StarInput(
            label: l10n.connectionDnsHostLabel,
            controller: _hostCtrl,
            readOnly: true,
            trailing: _copyButton(
              copied: _hostCopied,
              onPressed: _copyHost,
              semanticLabel: _hostCopied
                  ? l10n.connectionCopied
                  : l10n.connectionCopyHost,
            ),
          ),
          SizedBox(height: layout.s2),
          StarInput(
            label: l10n.connectionDnsValueLabel,
            controller: _valueCtrl,
            readOnly: true,
            trailing: _copyButton(
              copied: _valueCopied,
              onPressed: _copyValue,
              semanticLabel: _valueCopied
                  ? l10n.connectionCopied
                  : l10n.connectionCopyValue,
            ),
          ),
        ],
      ),
    );
  }

  Widget _copyButton({
    required bool copied,
    required VoidCallback onPressed,
    required String semanticLabel,
  }) {
    final colors = context.colors;
    return StarTappable(
      onTap: onPressed,
      semanticLabel: semanticLabel,
      builder: (context, _) => Container(
        width: 32,
        height: 32,
        alignment: Alignment.center,
        child: PhosphorIcon(
          copied ? PhosphorIconsFill.checkCircle : PhosphorIconsBold.clipboard,
          size: 16,
          color: copied ? colors.accentSuccess : colors.textSecondary,
        ),
      ),
    );
  }

  Widget _buildTokenCard() {
    final l10n = StarLocalizations.of(context);
    final layout = context.layout;
    final colors = context.colors;
    final textStyles = context.textStyles;

    return Container(
      padding: EdgeInsets.all(layout.s3),
      decoration: BoxDecoration(
        color: StarBottomSheet.cardColorOf(context),
        border: Border.all(color: colors.backgroundModifierAccent),
        borderRadius: layout.radiusMd,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.connectionTokenFileTitle,
            style: textStyles.label.copyWith(color: colors.textPrimary),
          ),
          SizedBox(height: layout.s2),
          _inlineCodeText(
            l10n.connectionTokenFileDescription,
            colors,
            textStyles.bodySmall,
          ),
          SizedBox(height: layout.s3),
          StarButton.secondary(
            label: l10n.connectionTokenFileDownload,
            size: StarButtonSize.compact,
            onPressedAsync: _saveTokenFile,
          ),
          SizedBox(height: layout.s2),
          _inlineCodeText(
            l10n.connectionTokenFileMeta(_dnsUrl),
            colors,
            textStyles.bodySmall,
          ),
        ],
      ),
    );
  }

  Widget _inlineCodeText(
    String template,
    StarColorTheme colors,
    TextStyle baseStyle,
  ) {
    final spans = <TextSpan>[];
    final regex = RegExp(r'\*\*(.+?)\*\*');
    var cursor = 0;
    for (final match in regex.allMatches(template)) {
      if (match.start > cursor) {
        spans.add(
          TextSpan(
            text: template.substring(cursor, match.start),
            style: baseStyle.copyWith(color: colors.textSecondary),
          ),
        );
      }
      spans.add(
        TextSpan(
          text: match.group(1),
          style: baseStyle.copyWith(
            fontFamily: 'monospace',
            color: colors.textPrimary,
            backgroundColor: colors.backgroundTertiary,
          ),
        ),
      );
      cursor = match.end;
    }
    if (cursor < template.length) {
      spans.add(
        TextSpan(
          text: template.substring(cursor),
          style: baseStyle.copyWith(color: colors.textSecondary),
        ),
      );
    }
    return RichText(text: TextSpan(children: spans));
  }

  Future<void> _copyHost() async {
    if (_hostCtrl == null) {
      return;
    }
    await copyToClipboard(context: context, value: _hostCtrl!.text);
    setState(() => _hostCopied = true);
    await Future<void>.delayed(const Duration(milliseconds: 1500));
    if (mounted) {
      setState(() => _hostCopied = false);
    }
  }

  Future<void> _copyValue() async {
    if (_valueCtrl == null) {
      return;
    }
    await copyToClipboard(context: context, value: _valueCtrl!.text);
    setState(() => _valueCopied = true);
    await Future<void>.delayed(const Duration(milliseconds: 1500));
    if (mounted) {
      setState(() => _valueCopied = false);
    }
  }

  Future<void> _saveTokenFile() async {
    if (_verification == null) {
      return;
    }
    final l10n = StarLocalizations.of(context);
    try {
      final bytes = utf8.encode(_verification!.token);
      final Uri? savedUri = await FilePicker.saveFile(
        dialogTitle: l10n.connectionSaveTokenDialogTitle,
        fileName: 'star-verification',
        bytes: bytes,
      );
      if (savedUri != null) {
        final String? filePath = savedUri.scheme == 'file'
            ? savedUri.toFilePath()
            : null;
        if (filePath != null) {
          final file = File(filePath);
          if (!file.existsSync() || file.lengthSync() == 0) {
            await file.writeAsString(_verification!.token);
          }
        }
        ref
            .read(toastProvider.notifier)
            .show(
              StarToast(
                message: l10n.connectionTokenSavedToast,
                variant: StarToastVariant.success,
              ),
            );
      }
    } on Object catch (_) {
      ref
          .read(toastProvider.notifier)
          .show(
            StarToast(
              message: l10n.connectionTokenSaveFailedToast,
              variant: StarToastVariant.danger,
            ),
          );
    }
  }

  Future<void> _onVerify() async {
    if (_verification == null) {
      return;
    }
    final l10n = StarLocalizations.of(context);
    try {
      await ref
          .read(connectionsViewModelProvider(readAccountUserId(ref)).notifier)
          .verifyAndCreate(_verification!.initiationToken);
      if (mounted) {
        widget.close();
      }
    } on Object catch (e) {
      setState(
        () => _error = userFacingErrorMessage(e, l10n.connectionVerifyFailed),
      );
    }
  }
}
