abstract final class InstanceConstants {
  static const int apiCodeVersion = 1;
  static const String defaultApiBaseUrl = 'https://star.invalid/api/v1';
  static const String defaultGatewayUrl = 'wss://gateway.star.invalid';
  static const String defaultInstanceInputUrl = 'star.invalid';
  static const String canaryApiBaseUrl = 'https://canary.star.invalid/api/v1';
  static const String canaryInstanceInputUrl = 'canary.star.invalid';
  static const String defaultTermsUrl = 'https://star.invalid/terms';
  static const String defaultPrivacyUrl = 'https://star.invalid/privacy';
  static const String helpCenterUrl = 'https://star.invalid/help';
  static const String defaultProductName = 'Star';
  static const String defaultPremiumProductName = 'Plutonium';
  static const int maxRecentInstances = 5;

  static const Set<String> officialInstanceHosts = <String>{
    'star.invalid',
    'web.star.invalid',
    'canary.star.invalid',
    'web.canary.star.invalid',
  };
}
