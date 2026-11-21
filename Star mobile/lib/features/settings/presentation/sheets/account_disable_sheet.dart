import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:star_app/core/api/dio_error_message.dart';
import 'package:star_app/core/api/star_client_provider.dart';
import 'package:star_app/core/api/sudo_interceptor.dart';
import 'package:star_app/core/providers/gateway/gateway_reconnect_provider.dart';
import 'package:star_app/core/theme/star_theme_extension.dart';
import 'package:star_app/features/auth/providers/account_closure_notice_provider.dart';
import 'package:star_app/features/settings/presentation/widgets/wide_settings_content_layout.dart';
import 'package:star_app/features/settings/utils/sign_out_current_account.dart';
import 'package:star_app/features/ui/bottom_sheet/star_bottom_sheet.dart';
import 'package:star_app/features/ui/button/star_button.dart';
import 'package:star_app/l10n/generated/star_localizations.dart';
import 'package:star_app/material_ui.dart';
import 'package:star_dart/export.dart';

class AccountDisableSheet extends ConsumerStatefulWidget {
  const AccountDisableSheet({super.key});

  static Future<void> show(BuildContext context, WidgetRef ref) {
    return StarBottomSheet.show<void>(
      context,
      title: StarLocalizations.of(context).dangerZoneDisableTitle,
      useRootNavigator: true,
      builder: (_, _) => const AccountDisableSheet(),
    );
  }

  @override
  ConsumerState<AccountDisableSheet> createState() =>
      _AccountDisableSheetState();
}

class _AccountDisableSheetState extends ConsumerState<AccountDisableSheet> {
  bool _loading = false;
  String? _error;

  Future<void> _handleDisable() async {
    final l10n = StarLocalizations.of(context);

    final ProviderContainer container = ProviderScope.containerOf(
      context,
      listen: false,
    );
    final NavigatorState rootNavigator = Navigator.of(
      context,
      rootNavigator: true,
    );

    setState(() {
      _loading = true;
      _error = null;
    });

    container
        .read(accountClosureInFlightProvider.notifier)
        .setInFlight(value: true);
    try {
      await container
          .read(starClientProvider)
          .users
          .disableCurrentUserAccount(body: const SudoVerificationSchema());
    } on DioException catch (e) {
      container
          .read(accountClosureInFlightProvider.notifier)
          .setInFlight(value: false);
      if (!mounted) {
        return;
      }
      setState(() {
        _loading = false;
        _error = isSudoCancellation(e)
            ? null
            : userFacingErrorMessage(e, l10n.genericError);
      });
      return;
    }

    container
        .read(pendingAccountClosureNoticeProvider.notifier)
        .show(const AccountClosureNotice(kind: AccountClosureKind.disabled));
    rootNavigator.popUntil((Route<dynamic> route) => route.isFirst);
    await signOutCurrentAccount(container, keepInstance: true);
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
            l10n.dangerZoneDisableConfirmDescription,
            style: context.textStyles.bodySmall.copyWith(
              color: colors.textSecondary,
            ),
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
                child: StarButton.dangerPrimary(
                  onPressed: _loading ? null : _handleDisable,
                  label: l10n.dangerZoneDisableTitle,
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
