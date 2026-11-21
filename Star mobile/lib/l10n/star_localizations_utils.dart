import 'dart:ui' show Locale;

import 'package:flutter/widgets.dart' show basicLocaleListResolution;
import 'package:star_app/l10n/generated/star_localizations.dart';
import 'package:star_dart/models/locale.dart' as sdk;

Locale? tryFlutterLocaleFromSdkLocale(sdk.Locale locale) {
  final String? tag = locale.json;
  return tag == null ? null : tryFlutterLocaleFromLocaleTag(tag);
}

Locale? tryFlutterLocaleFromLocaleTag(String tag) {
  final Locale? candidate = switch (tag) {
    'en-US' => const Locale('en', 'US'),
    'en-GB' => const Locale('en', 'GB'),
    'es-ES' => const Locale('es'),
    'es-419' => const Locale('es', '419'),
    'pt-BR' => const Locale('pt', 'BR'),
    'pt-PT' => const Locale('pt'),
    'sv-SE' => const Locale('sv'),
    'zh-CN' => const Locale('zh'),
    'zh-TW' => const Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hant'),
    'no' => const Locale('nb'),
    'tok' => const Locale('art'),
    _ when !tag.contains('-') => Locale(tag),
    _ => null,
  };
  return candidate != null &&
          StarLocalizations.supportedLocales.contains(candidate)
      ? candidate
      : null;
}

Locale resolveSupportedStarLocales(List<Locale> preferredLocales) {
  return basicLocaleListResolution(
    preferredLocales.map(_withFilipinoForTagalog).toList(),
    StarLocalizations.supportedLocales,
  );
}

Locale _withFilipinoForTagalog(Locale locale) {
  if (locale.languageCode != 'tl') {
    return locale;
  }
  return Locale.fromSubtags(
    languageCode: 'fil',
    scriptCode: locale.scriptCode,
    countryCode: locale.countryCode,
  );
}
