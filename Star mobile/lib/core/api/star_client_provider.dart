import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:star_app/core/age/declared_age_range_lock.dart';
import 'package:star_app/core/api/accept_language_interceptor.dart';
import 'package:star_app/core/api/attachment_request_auth.dart';
import 'package:star_app/core/api/captcha_interceptor.dart';
import 'package:star_app/core/api/star_api_features.dart';
import 'package:star_app/core/api/star_client_properties.dart';
import 'package:star_app/core/api/premium_state_response_interceptor.dart';
import 'package:star_app/core/api/rate_limit_interceptor.dart';
import 'package:star_app/core/api/retry_interceptor.dart';
import 'package:star_app/core/api/session_auth_interceptor.dart';
import 'package:star_app/core/api/skip_auth_interceptor.dart';
import 'package:star_app/core/api/sudo_dialog.dart';
import 'package:star_app/core/api/sudo_interceptor.dart';
import 'package:star_app/core/bootstrap/image_cache_config.dart';
import 'package:star_app/core/instance/instance_config_snapshot.dart';
import 'package:star_app/core/instance/instance_endpoint_normalizer.dart';
import 'package:star_app/core/instance/instance_endpoints.dart';
import 'package:star_app/core/observability/star_measure_dio.dart';
import 'package:star_app/core/observability/measure_http_policy.dart';
import 'package:star_app/core/providers/app_runtime_info_provider.dart';
import 'package:star_app/core/providers/gateway/gateway_connection_provider.dart';
import 'package:star_app/core/providers/instance/active_instance_provider.dart';
import 'package:star_app/core/router/star_router.dart';
import 'package:star_app/core/talker.dart';
import 'package:star_app/features/auth/data/auth_repository.dart';
import 'package:star_app/features/auth/data/sso_auth_service.dart';
import 'package:star_app/features/auth/providers/auth_instance_snapshot_provider.dart';
import 'package:star_app/features/auth/providers/auth_providers.dart';
import 'package:star_app/features/ui/toast/star_toast.dart';
import 'package:star_app/features/ui/toast/toast_provider.dart';
import 'package:star_app/l10n/app_locale_provider.dart';
import 'package:star_dart/export.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:talker_dio_logger/talker_dio_logger.dart';

export 'package:star_app/core/providers/instance/active_instance_provider.dart';

part 'star_client_provider.g.dart';

@Riverpod(keepAlive: true)
StarClientProperties starClientProperties(Ref ref) {
  final AsyncValue<AppRuntimeInfo> runtime = ref.watch(appRuntimeInfoProvider);
  return runtime.when(
    data: (AppRuntimeInfo info) =>
        buildStarClientProperties(runtimeInfo: info),
    loading: buildStarClientProperties,
    error: (Object err, StackTrace stack) => buildStarClientProperties(),
  );
}

@Riverpod(keepAlive: true)
String starClientPropertiesHeader(Ref ref) {
  final StarClientProperties properties = ref.watch(
    starClientPropertiesProvider,
  );
  return encodeStarClientPropertiesHeader(
    toClientPropertiesWireMap(properties),
  );
}

Dio _buildStarDio({
  required Ref ref,
  required String baseUrl,
  required InstanceConfigSnapshot instanceSnapshot,
}) {
  final String userAgent = ref.watch(starClientPropertiesProvider).userAgent;
  final String clientPropertiesHeader = ref.watch(
    starClientPropertiesHeaderProvider,
  );
  final Dio dio = Dio(
    BaseOptions(
      baseUrl: baseUrl,
      contentType: 'application/json',
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 10),
      headers: <String, dynamic>{
        'User-Agent': userAgent,
        'X-Star-Client-Properties': clientPropertiesHeader,
        starApiFeaturesHeaderName: buildStarApiFeaturesHeaderValue(),
      },
    ),
  );
  final ProviderContainer container = ref.container;
  dio.interceptors.add(
    AcceptLanguageInterceptor(
      readLocale: () => container.read(effectiveAppLocaleProvider),
    ),
  );
  String? readToken() => ref.read(starAuthTokenProvider);
  dio.interceptors.add(
    SessionAuthInterceptor(
      readToken: readToken,
      readTokenBaseUrl: () =>
          container.read(starAuthTokenProvider.notifier).issuerBaseUrl,
    ),
  );
  dio.interceptors.add(SkipAuthInterceptor());
  dio.interceptors.add(RetryInterceptor(dio: dio, readToken: readToken));
  final RateLimitPacer rateLimitPacer = RateLimitPacer();
  ref.listen<String?>(
    starAuthTokenProvider,
    (String? previous, String? next) => rateLimitPacer.clear(),
  );
  dio.interceptors.add(RateLimitInterceptor(pacer: rateLimitPacer));
  dio.interceptors.add(PremiumStateResponseInterceptor());
  attachStarMeasureDioInterceptor(
    dio,
    shouldTrackRequest: (Uri uri) => kMeasureHttpPolicy.shouldTrackHttpRequest(
      instance: instanceSnapshot,
      requestUri: uri,
    ),
  );
  dio.interceptors.add(
    CaptchaInterceptor(
      dio: dio,
      showSlowSolveHint: () {
        final StarToast toast = StarToast(
          message: ref.read(appLocalizationsProvider).authCheckStillWorking,
          duration: const Duration(seconds: 60),
        );
        ref.read(toastProvider.notifier).show(toast);
        return () => ref.read(toastProvider.notifier).hide(toast);
      },
    ),
  );
  final SudoInterceptor sudoInterceptor = SudoInterceptor(
    dio: dio,
    showSudoSheet: (SudoChallenge challenge) => showSudoVerificationSheet(
      navigatorKey: rootNavigatorKey.currentState != null
          ? rootNavigatorKey
          : declaredAgeRangeNavigatorKey,
      dio: dio,
      challenge: challenge,
      passkeysSupported: passkeysSupportedFor(instanceSnapshot.apiBaseUrl),
      reauthenticateWithSso: () => _reauthenticateWithSso(container),
      ssoProviderName: instanceSnapshot.ssoConfig?.displayName,
    ),
  );
  ref.listen<String?>(
    starAuthTokenProvider,
    (String? previous, String? next) => sudoInterceptor.clearCachedToken(),
  );
  dio.interceptors.add(sudoInterceptor);
  if (kDebugMode) {
    dio.interceptors.add(
      TalkerDioLogger(
        settings: const TalkerDioLoggerSettings(
          printResponseTime: true,
          printResponseData: false,
          printRequestData: false,
          printErrorData: false,
          printErrorHeaders: false,
        ),
      ),
    );
  }
  return dio;
}

Future<bool?> _reauthenticateWithSso(ProviderContainer container) async {
  final AuthRepository repository = container.read(authRepositoryProvider);
  try {
    final SsoStartResponse start = await repository.startSso(
      redirectUri: 'star://auth/sso/callback',
    );
    final Uri callback = await container
        .read(ssoAuthServiceProvider)
        .authenticate(authorizationUrl: start.authorizationUrl);
    final String? code = callback.queryParameters['code'];
    final String? state = callback.queryParameters['state'];
    if (code == null || code.isEmpty || state == null || state.isEmpty) {
      return null;
    }
    final ({String token, String userId})? session = await repository
        .completeSsoReauth(code: code, state: state);
    if (session == null) {
      return null;
    }
    if (session.userId != container.read(currentUserIdProvider)) {
      return false;
    }
    container.read(gatewayConnectionProvider).setToken(session.token);
    container.read(starAuthTokenProvider.notifier).setToken(session.token);
    await repository.persistRotatedToken(session.token);
    return true;
  } on SsoAuthCancelledException {
    return null;
  } on Exception catch (error) {
    talker.warning('[Sudo] SSO re-authentication failed: $error');
    return null;
  }
}

@Riverpod(keepAlive: true)
Dio starDio(Ref ref) {
  final String baseUrl = ref.watch(starBaseUrlProvider);
  final InstanceConfigSnapshot instance = ref.watch(activeInstanceProvider);
  final Dio dio = _buildStarDio(
    ref: ref,
    baseUrl: baseUrl,
    instanceSnapshot: instance,
  );
  void syncAttachmentAuth() => AttachmentRequestAuth.update(
    token: ref.read(starAuthTokenProvider),
    baseUrl: ref.read(starAuthTokenProvider.notifier).issuerBaseUrl,
    mintToken: ({required String url}) => _mintAttachmentToken(dio, url: url),
  );
  syncAttachmentAuth();
  ref.listen<String?>(starAuthTokenProvider, (
    String? previous,
    String? next,
  ) {
    syncAttachmentAuth();
    if (previous != null &&
        previous != next &&
        InstanceEndpoints.proxyAttachmentsThroughApi) {
      unawaited(clearStarNetworkImageCaches());
    }
  });
  return dio;
}

Future<AttachmentMediaToken?> _mintAttachmentToken(
  Dio dio, {
  required String url,
}) async {
  final Response<Map<String, dynamic>> response = await dio
      .post<Map<String, dynamic>>(
        '/users/@me/attachment-token',
        data: <String, dynamic>{'url': url},
      );
  final Object? token = response.data?['token'];
  final Object? expiresAt = response.data?['expires_at'];
  final DateTime? expiry = expiresAt is String
      ? DateTime.tryParse(expiresAt)
      : null;
  if (token is! String || token.isEmpty || expiry == null) {
    return null;
  }
  return AttachmentMediaToken(token: token, expiresAt: expiry);
}

@Riverpod(keepAlive: true)
StarClient starClient(Ref ref) {
  final Dio dio = ref.watch(starDioProvider);
  final String baseUrl = ref.watch(starBaseUrlProvider);
  return StarClient(dio, baseUrl: baseUrl);
}

@Riverpod(keepAlive: true)
String authStarBaseUrl(Ref ref) {
  return ref.watch(authInstanceSnapshotProvider).apiBaseUrl;
}

@Riverpod(keepAlive: true)
Dio authStarDio(Ref ref) {
  final String baseUrl = ref.watch(authStarBaseUrlProvider);
  final InstanceConfigSnapshot instance = ref.watch(
    authInstanceSnapshotProvider,
  );
  return _buildStarDio(
    ref: ref,
    baseUrl: baseUrl,
    instanceSnapshot: instance,
  );
}

@Riverpod(keepAlive: true)
StarClient authStarClient(Ref ref) {
  final Dio dio = ref.watch(authStarDioProvider);
  final String baseUrl = ref.watch(authStarBaseUrlProvider);
  return StarClient(dio, baseUrl: baseUrl);
}

@Riverpod(keepAlive: true)
class StarAuthToken extends _$StarAuthToken {
  String? _issuerBaseUrl;

  String? get issuerBaseUrl => _issuerBaseUrl;

  @override
  String? build() {
    _issuerBaseUrl = null;
    return null;
  }

  void setToken(String? token, {String? issuerBaseUrl}) {
    final String? issuer = token == null || token.isEmpty
        ? null
        : issuerBaseUrl ?? ref.read(starBaseUrlProvider);
    if (state == token && _issuerBaseUrl == issuer) {
      return;
    }
    _issuerBaseUrl = issuer;
    if (state == token) {
      ref.notifyListeners();
      return;
    }
    state = token;
  }

  bool isIssuedBy(String apiBaseUrl) {
    final String? token = state;
    final String? issuer = _issuerBaseUrl;
    return token != null &&
        token.isNotEmpty &&
        issuer != null &&
        isSameBaseUrl(issuer, apiBaseUrl);
  }
}
