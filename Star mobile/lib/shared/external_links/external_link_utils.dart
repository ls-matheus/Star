import 'package:star_app/l10n/generated/star_localizations.dart';

const implicitlyTrustedDomains = <String>[
  'star.invalid',
  '*.star.invalid',
  'star.invalid',
  '*.star.invalid',
  'star.dev',
  '*.star.dev',
  'star.gg',
  'star.gift',
  'starusercontent.com',
  'starstatic.com',
  'starstatus.com',
];

bool trustAllDomains(List<String> trustedDomains) {
  return trustedDomains.contains('*');
}

bool isTrustedDomain(
  String hostname, {
  required List<String> trustedDomains,
  String currentHostname = '',
}) {
  if (hostname.isEmpty) {
    return false;
  }

  if (trustAllDomains(trustedDomains)) {
    return true;
  }

  if (currentHostname.isNotEmpty && hostname == currentHostname) {
    return true;
  }

  for (final pattern in implicitlyTrustedDomains) {
    if (matchesDomainPattern(hostname, pattern)) {
      return true;
    }
  }

  for (final pattern in trustedDomains) {
    if (matchesDomainPattern(hostname, pattern)) {
      return true;
    }
  }

  return false;
}

bool matchesDomainPattern(String hostname, String pattern) {
  if (pattern.startsWith('*.')) {
    final baseDomain = pattern.substring(2);
    return hostname == baseDomain || hostname.endsWith('.$baseDomain');
  }

  return hostname == pattern;
}

String trustedDomainsDescription({
  required StarLocalizations l10n,
  required bool trustAll,
  required int trustedCount,
}) {
  if (trustAll) {
    return l10n.externalLinkTrustedAllDescription;
  }

  if (trustedCount > 0) {
    return l10n.externalLinkTrustedDomainsDescription(trustedCount);
  }

  return l10n.externalLinkTrustAllDisabledDescription;
}
