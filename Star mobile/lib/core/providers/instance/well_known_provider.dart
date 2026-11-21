import 'dart:async';

import 'package:dio/dio.dart';

import 'package:star_app/core/api/star_client_provider.dart';
import 'package:star_app/core/instance/instance_compatibility.dart';
import 'package:star_app/core/instance/instance_config_snapshot.dart';
import 'package:star_app/core/instance/instance_discovery_service.dart';
import 'package:star_app/core/instance/instance_endpoint_normalizer.dart';
import 'package:star_app/core/instance/instance_endpoints.dart';
import 'package:star_app/core/talker.dart';
import 'package:star_app/features/auth/providers/auth_providers.dart';
import 'package:star_dart/export.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'well_known_provider.g.dart';

@Riverpod(keepAlive: true)
class WellKnown extends _$WellKnown {
  @override
  Future<WellKnownStarResponse> build() async {
    final InstanceConfigSnapshot snapshot = ref.watch(activeInstanceProvider);
    final WellKnownStarResponse? cached = snapshot.wellKnown;
    if (cached != null) {
      InstanceCompatibility.validateWellKnownDocument(cached);
      InstanceEndpoints.apply(cached);
      unawaited(Future<void>.microtask(refresh));
      return cached;
    }
    final WellKnownStarResponse response = await _fetch(
      ref.watch(starDioProvider),
    );
    if (!_applyIfMounted(response)) {
      return response;
    }
    unawaited(_persistSnapshot(response));
    return response;
  }

  Future<void> refresh({bool silent = true}) async {
    if (!ref.mounted) {
      return;
    }
    if (!silent) {
      state = const AsyncLoading<WellKnownStarResponse>();
    }
    final String apiBaseUrl = ref.read(starBaseUrlProvider);
    try {
      final WellKnownStarResponse response = await _fetch(
        ref.read(starDioProvider),
      );
      if (!ref.mounted || ref.read(starBaseUrlProvider) != apiBaseUrl) {
        return;
      }
      if (!_applyIfMounted(response)) {
        return;
      }
      state = AsyncData<WellKnownStarResponse>(response);
      await _persistSnapshot(response);
    } on InstanceDiscoveryException catch (error, stackTrace) {
      if (!ref.mounted) {
        return;
      }
      if (silent && state.hasValue && !_isCompatibilityFailure(error)) {
        return;
      }
      state = AsyncError<WellKnownStarResponse>(error, stackTrace);
    } on Object catch (error, stackTrace) {
      if (!ref.mounted) {
        return;
      }
      if (silent && state.hasValue) {
        return;
      }
      state = AsyncError<WellKnownStarResponse>(error, stackTrace);
    }
  }

  static bool _isCompatibilityFailure(InstanceDiscoveryException error) {
    return error.reason == InstanceDiscoveryFailureReason.instanceOutdated ||
        error.reason == InstanceDiscoveryFailureReason.requiresNewerClient;
  }

  Future<WellKnownStarResponse> _fetch(Dio dio) async {
    final Response<Map<String, dynamic>> result = await dio
        .get<Map<String, dynamic>>('/.well-known/star');
    final Map<String, dynamic>? data = result.data;
    if (data == null) {
      throw const InstanceDiscoveryException(
        'Invalid instance discovery response',
        reason: InstanceDiscoveryFailureReason.invalidDiscoveryResponse,
      );
    }
    final Map<String, dynamic> payload = Map<String, dynamic>.from(data);
    InstanceCompatibility.validateDiscoveryPayload(payload);
    final WellKnownStarResponse parsed =
        InstanceConfigSnapshot.parseWellKnown(payload);
    InstanceCompatibility.validateWellKnownDocument(parsed);
    return parsed;
  }

  bool _applyIfMounted(WellKnownStarResponse response) {
    if (!ref.mounted) {
      return false;
    }
    InstanceEndpoints.apply(response);
    return true;
  }

  Future<void> _persistSnapshot(WellKnownStarResponse response) async {
    if (!ref.mounted) {
      return;
    }
    try {
      await ref
          .read(authRepositoryProvider)
          .persistInstanceSnapshot(
            ref.read(activeInstanceProvider).withWellKnown(response),
          );
    } on Object catch (error, stackTrace) {
      talker.warning(
        '[WellKnown] Failed to persist instance snapshot: $error\n$stackTrace',
      );
    }
  }
}

@Riverpod(keepAlive: true)
InstanceConfigSnapshot refreshedActiveInstance(Ref ref) {
  final InstanceConfigSnapshot instance = ref.watch(activeInstanceProvider);
  final WellKnownStarResponse? fresh = ref
      .watch(wellKnownProvider)
      .asData
      ?.value;
  if (fresh == null || identical(fresh, instance.wellKnown)) {
    return instance;
  }
  return instance.withWellKnown(fresh);
}

@Riverpod(keepAlive: true)
String instanceInviteBaseUrl(Ref ref) {
  final AsyncValue<WellKnownStarResponse> wellKnown = ref.watch(
    wellKnownProvider,
  );
  return wellKnown.when(
    data: (WellKnownStarResponse response) => response.endpoints.invite,
    loading: () => InstanceEndpoints.invite,
    error: (_, _) => InstanceEndpoints.invite,
  );
}

@Riverpod(keepAlive: true)
String instanceGiftBaseUrl(Ref ref) {
  final AsyncValue<WellKnownStarResponse> wellKnown = ref.watch(
    wellKnownProvider,
  );
  return wellKnown.when(
    data: (WellKnownStarResponse response) => response.endpoints.gift,
    loading: () => InstanceEndpoints.gift,
    error: (_, _) => InstanceEndpoints.gift,
  );
}

@Riverpod(keepAlive: true)
String instanceStaticCdnBaseUrl(Ref ref) {
  final AsyncValue<WellKnownStarResponse> wellKnown = ref.watch(
    wellKnownProvider,
  );
  return wellKnown.when(
    data: (WellKnownStarResponse response) => response.endpoints.staticCdn,
    loading: () => InstanceEndpoints.staticCdn,
    error: (_, _) => InstanceEndpoints.staticCdn,
  );
}

@Riverpod(keepAlive: true)
String instanceMediaBaseUrl(Ref ref) {
  final AsyncValue<WellKnownStarResponse> wellKnown = ref.watch(
    wellKnownProvider,
  );
  return wellKnown.when(
    data: (WellKnownStarResponse response) => response.endpoints.media,
    loading: () => InstanceEndpoints.media,
    error: (_, _) => InstanceEndpoints.media,
  );
}

@Riverpod(keepAlive: true)
String instanceWebAppBaseUrl(Ref ref) {
  final AsyncValue<WellKnownStarResponse> wellKnown = ref.watch(
    wellKnownProvider,
  );
  return wellKnown.when(
    data: (WellKnownStarResponse response) => response.endpoints.webapp,
    loading: () => InstanceEndpoints.webApp,
    error: (_, _) => InstanceEndpoints.webApp,
  );
}

@Riverpod(keepAlive: true)
String instanceWebAppAddress(Ref ref) {
  return const InstanceEndpointNormalizer().describeApiEndpoint(
    ref.watch(instanceWebAppBaseUrlProvider),
  );
}
