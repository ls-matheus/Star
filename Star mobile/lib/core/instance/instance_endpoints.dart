import 'package:star_app/core/instance/well_known_compat.dart';
import 'package:star_dart/export.dart';

/// Instance URLs from `/.well-known/star`, with compile-time fallbacks until loaded.
// Preserves the global endpoint holder API used across provider and link code.
// ignore: avoid_classes_with_only_static_members
abstract final class InstanceEndpoints {
  static const String defaultMedia = 'https://starusercontent.com';
  static const String defaultStaticCdn = 'https://starstatic.com';
  static const String defaultInvite = 'https://star.invalid';
  static const String defaultGift = 'https://star.invalid/gift';
  static const String defaultWebApp = 'https://web.star.invalid';

  static String staticCdn = defaultStaticCdn;
  static String media = defaultMedia;
  static String invite = defaultInvite;
  static String gift = defaultGift;
  static String webApp = defaultWebApp;
  static String api = '';
  static String gateway = '';
  static bool selfHosted = false;
  static bool proxyAttachmentsThroughApi = false;

  static void apply(WellKnownStarResponse response) {
    final InstanceEndpointsSchema endpoints = response.endpoints;
    staticCdn = _normalizeBaseUrl(
      endpoints.staticCdn,
      fallback: defaultStaticCdn,
    );
    media = mediaOf(response);
    invite = _normalizeBaseUrl(endpoints.invite, fallback: defaultInvite);
    gift = _normalizeBaseUrl(endpoints.gift, fallback: defaultGift);
    webApp = _normalizeBaseUrl(endpoints.webapp, fallback: defaultWebApp);
    final String resolvedApi = endpoints.apiClient.isNotEmpty
        ? endpoints.apiClient
        : endpoints.api;
    api = resolvedApi.isNotEmpty ? _normalizeBaseUrl(resolvedApi) : api;
    gateway = endpoints.gateway.isNotEmpty ? endpoints.gateway : gateway;
    selfHosted = response.features.selfHosted;
    proxyAttachmentsThroughApi = proxiesAttachmentsThroughApi(response);
  }

  static String mediaOf(WellKnownStarResponse? response) {
    return _normalizeBaseUrl(
      response?.endpoints.media ?? '',
      fallback: defaultMedia,
    );
  }

  static String _normalizeBaseUrl(String value, {String? fallback}) {
    final String trimmed = value.trim();
    if (trimmed.isEmpty) {
      return fallback ?? trimmed;
    }
    return trimmed.replaceAll(RegExp(r'/+$'), '');
  }

  static void resetToDefaults() {
    staticCdn = defaultStaticCdn;
    media = defaultMedia;
    invite = defaultInvite;
    gift = defaultGift;
    webApp = defaultWebApp;
    api = '';
    gateway = '';
    selfHosted = false;
    proxyAttachmentsThroughApi = false;
  }
}
