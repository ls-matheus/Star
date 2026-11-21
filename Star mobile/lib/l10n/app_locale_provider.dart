import 'dart:ui' show Locale, PlatformDispatcher;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:star_app/features/profile/providers/user_settings_status_provider.dart';
import 'package:star_app/l10n/star_localizations_utils.dart';
import 'package:star_app/l10n/generated/star_localizations.dart';
import 'package:star_dart/models/locale.dart' as sdk;
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'app_locale_provider.g.dart';

List<Locale> _currentPlatformLocales() {
  final List<Locale> locales = PlatformDispatcher.instance.locales;
  if (locales.isNotEmpty) {
    return List<Locale>.unmodifiable(locales);
  }
  return <Locale>[PlatformDispatcher.instance.locale];
}

@Riverpod(keepAlive: true)
class SystemLocales extends _$SystemLocales {
  @override
  List<Locale> build() => _currentPlatformLocales();

  void updateFromPlatform(List<Locale>? locales) {
    state = locales == null || locales.isEmpty
        ? _currentPlatformLocales()
        : List<Locale>.unmodifiable(locales);
  }
}

@Riverpod(keepAlive: true)
Locale effectiveAppLocale(Ref ref) {
  final sdk.Locale? selected = ref.watch(
    userSettingsStatusProvider.select((settings) => settings?.locale),
  );
  final Locale? selectedLocale = selected == null
      ? null
      : tryFlutterLocaleFromSdkLocale(selected);
  if (selectedLocale != null) {
    return selectedLocale;
  }
  return resolveSupportedStarLocales(ref.watch(systemLocalesProvider));
}

@Riverpod(keepAlive: true)
StarLocalizations appLocalizations(Ref ref) {
  return lookupStarLocalizations(ref.watch(effectiveAppLocaleProvider));
}
