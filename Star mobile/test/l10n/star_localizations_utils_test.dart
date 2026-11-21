import 'dart:ui' show Locale;

import 'package:flutter_test/flutter_test.dart';
import 'package:star_app/l10n/star_localizations_utils.dart';
import 'package:star_dart/models/locale.dart' as sdk;

void main() {
  test('tryFlutterLocaleFromSdkLocale maps supported regional tags', () {
    expect(
      tryFlutterLocaleFromSdkLocale(sdk.Locale.enUs),
      const Locale('en', 'US'),
    );
    expect(
      tryFlutterLocaleFromSdkLocale(sdk.Locale.enGb),
      const Locale('en', 'GB'),
    );
    expect(
      tryFlutterLocaleFromSdkLocale(sdk.Locale.es419),
      const Locale('es', '419'),
    );
    expect(
      tryFlutterLocaleFromSdkLocale(sdk.Locale.zhTw),
      const Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hant'),
    );
    expect(tryFlutterLocaleFromSdkLocale(sdk.Locale.de), const Locale('de'));
  });

  test('tryFlutterLocaleFromLocaleTag maps the newer API tags', () {
    const Map<String, Locale> cases = <String, Locale>{
      'be': Locale('be'),
      'bn': Locale('bn'),
      'ca': Locale('ca'),
      'fil': Locale('fil'),
      'lv': Locale('lv'),
      'pt-BR': Locale('pt', 'BR'),
      'pt-PT': Locale('pt'),
      'sk': Locale('sk'),
      'sl': Locale('sl'),
      'sq': Locale('sq'),
      'tok': Locale('art'),
    };
    for (final MapEntry<String, Locale> entry in cases.entries) {
      expect(
        tryFlutterLocaleFromLocaleTag(entry.key),
        entry.value,
        reason: entry.key,
      );
    }
  });

  test('every backend locale has a bundled catalog', () {
    for (final sdk.Locale locale in sdk.Locale.$valuesDefined) {
      expect(
        tryFlutterLocaleFromSdkLocale(locale),
        isNotNull,
        reason: locale.toString(),
      );
    }
    expect(tryFlutterLocaleFromSdkLocale(sdk.Locale.$unknown), isNull);
  });

  test(
    'resolveSupportedStarLocales preserves regional and script variants',
    () {
      const List<Locale> variants = <Locale>[
        Locale('en', 'GB'),
        Locale('en', 'US'),
        Locale('es', '419'),
        Locale('pt', 'BR'),
        Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hant'),
      ];

      for (final Locale locale in variants) {
        expect(resolveSupportedStarLocales(<Locale>[locale]), locale);
      }
    },
  );

  test('Portuguese outside Brazil resolves to the European catalog', () {
    for (final String country in <String>['PT', 'AO', 'MZ', 'CV', 'GW']) {
      expect(
        resolveSupportedStarLocales(<Locale>[Locale('pt', country)]),
        const Locale('pt'),
        reason: country,
      );
    }
    expect(
      resolveSupportedStarLocales(const <Locale>[Locale('pt', 'BR')]),
      const Locale('pt', 'BR'),
    );
  });

  test('Tagalog device locales resolve to Filipino', () {
    expect(
      resolveSupportedStarLocales(const <Locale>[Locale('tl', 'PH')]),
      const Locale('fil'),
    );
  });

  test('resolveSupportedStarLocales checks every preferred locale', () {
    expect(
      resolveSupportedStarLocales(const <Locale>[
        Locale('xx', 'XX'),
        Locale('en', 'GB'),
      ]),
      const Locale('en', 'GB'),
    );
  });

  test('unsupported locales fall back to the default supported locale', () {
    expect(
      resolveSupportedStarLocales(const <Locale>[Locale('xx', 'XX')]),
      const Locale('en'),
    );
  });
}
