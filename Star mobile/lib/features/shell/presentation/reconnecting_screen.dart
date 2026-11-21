import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:star_app/core/providers/app/app_ui_lifecycle_provider.dart';
import 'package:star_app/core/providers/gateway/gateway_connection_provider.dart';
import 'package:star_app/core/providers/gateway/gateway_reconnect_provider.dart';
import 'package:star_app/core/router/star_router.dart';
import 'package:star_app/core/talker.dart';
import 'package:star_app/core/theme/star_theme_extension.dart';
import 'package:star_app/features/auth/presentation/widgets/offline_account_switcher_link.dart';
import 'package:star_app/features/shell/presentation/widgets/service_status_connection_footer.dart';
import 'package:star_app/features/shell/providers/service_status/service_status_incident_provider.dart';
import 'package:star_app/features/ui/spinner/star_loading_spinner.dart';
import 'package:star_app/l10n/generated/star_localizations.dart';
import 'package:star_app/material_ui.dart';
import 'package:star_app/shared/icons/phosphor.dart';
import 'package:star_dart/gateway.dart';

const Duration kReconnectingScreenRetryInterval = Duration(seconds: 20);

class ReconnectingScreen extends ConsumerStatefulWidget {
  const ReconnectingScreen({super.key});

  @override
  ConsumerState<ReconnectingScreen> createState() => _ReconnectingScreenState();
}

class _ReconnectingScreenState extends ConsumerState<ReconnectingScreen> {
  Timer? _retryTimer;
  var _nudgeInFlight = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      unawaited(_nudgeConnection());
      unawaited(ref.read(serviceStatusIncidentReadProvider.notifier).refresh());
      _retryTimer = Timer.periodic(kReconnectingScreenRetryInterval, (_) {
        if (!mounted) {
          return;
        }
        unawaited(_nudgeConnection());
      });
    });
  }

  @override
  void dispose() {
    _retryTimer?.cancel();
    super.dispose();
  }

  Future<void> _nudgeConnection() async {
    if (_nudgeInFlight ||
        !ref.read(authStateProvider) ||
        !ref.read(gatewayHasAuthTokenProvider)) {
      return;
    }
    _nudgeInFlight = true;
    try {
      final GatewayConnection connection = ref.read(gatewayConnectionProvider);
      await nudgeGatewayConnectionReconnect(connection, forceReconnect: true);
    } on Exception catch (error, stackTrace) {
      talker.warning('[Gateway] Reconnect nudge failed', error, stackTrace);
    } finally {
      _nudgeInFlight = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final StarLocalizations strings = StarLocalizations.of(context);
    ref.listen<bool>(appUiForegroundProvider, (bool? previous, bool next) {
      if (previous == false && next) {
        unawaited(_nudgeConnection());
      }
    });
    return Scaffold(
      backgroundColor: context.colors.backgroundPrimary,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            PhosphorIcon(
              PhosphorIconsFill.plugsConnected,
              size: 48,
              color: context.colors.textPrimaryMuted,
            ),
            const SizedBox(height: 16),
            Text(
              strings.reconnectingTitle,
              style: context.textStyles.heading.copyWith(
                fontSize: 28,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              strings.reconnectingBody,
              textAlign: TextAlign.center,
              style: context.textStyles.bodyMedium.copyWith(
                color: context.colors.textPrimaryMuted,
              ),
            ),
            const SizedBox(height: 24),
            const StarLoadingSpinner(),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: ServiceStatusConnectionFooter(
                promptStyle: context.textStyles.bodySmall.copyWith(
                  color: context.colors.textPrimaryMuted,
                ),
                linkStyle: context.textStyles.bodySmall.copyWith(
                  color: context.colors.textLink,
                ),
              ),
            ),
            const SizedBox(height: 16),
            const OfflineAccountSwitcherLink(),
          ],
        ),
      ),
    );
  }
}
