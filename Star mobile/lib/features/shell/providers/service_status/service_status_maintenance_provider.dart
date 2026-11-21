import 'dart:async';

import 'package:star_app/core/providers/instance/well_known_provider.dart';
import 'package:star_app/features/shell/data/service_status_client.dart';
import 'package:star_app/features/shell/domain/service_status_maintenance.dart';
import 'package:star_app/features/shell/utils/service_status_poll_delay.dart';
import 'package:star_dart/export.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'service_status_maintenance_provider.g.dart';

@Riverpod(keepAlive: true)
class ServiceStatusMaintenanceRead extends _$ServiceStatusMaintenanceRead {
  Timer? _pollTimer;
  bool _refreshInFlight = false;
  bool _refreshQueued = false;
  final ServiceStatusClient _client = ServiceStatusClient();

  @override
  ServiceStatusMaintenance? build() {
    ref
      ..onDispose(_cancelPoll)
      ..listen<AsyncValue<WellKnownStarResponse>>(wellKnownProvider, (
        _,
        AsyncValue<WellKnownStarResponse> next,
      ) {
        next.whenData((_) => unawaited(refresh()));
      }, fireImmediately: true);
    return null;
  }

  Future<void> refresh() async {
    if (_refreshInFlight) {
      _refreshQueued = true;
      return;
    }
    _refreshInFlight = true;
    try {
      final AsyncValue<WellKnownStarResponse> wellKnown = ref.read(
        wellKnownProvider,
      );
      final bool isSelfHosted = wellKnown.maybeWhen(
        data: (WellKnownStarResponse response) =>
            response.features.selfHosted,
        orElse: () => false,
      );
      if (isSelfHosted) {
        _cancelPoll();
        state = null;
        return;
      }
      final ServiceStatusMaintenance? next = await _client
          .fetchScheduledMaintenance();
      state = next;
      _scheduleNextPoll(next);
    } finally {
      _refreshInFlight = false;
      if (_refreshQueued && ref.mounted) {
        _refreshQueued = false;
        unawaited(refresh());
      }
    }
  }

  void _scheduleNextPoll(ServiceStatusMaintenance? maintenance) {
    _cancelPoll();
    final Duration delay = computeServiceStatusPollDelay(maintenance);
    _pollTimer = Timer(delay, () {
      unawaited(refresh());
    });
  }

  void _cancelPoll() {
    _pollTimer?.cancel();
    _pollTimer = null;
  }
}
