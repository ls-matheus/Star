import 'dart:ui' show Locale, PlatformDispatcher;

import 'package:star_app/l10n/generated/star_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String _kPushNotificationLocaleKey = 'push_notification_locale';

StarLocalizations? _mirrored;

StarLocalizations pushNotificationLocalizations() {
  return _mirrored ?? _lookup(PlatformDispatcher.instance.locale);
}

Future<void> loadPushNotificationLocale() async {
  try {
    final String? tag = await SharedPreferencesAsync().getString(
      _kPushNotificationLocaleKey,
    );
    if (tag != null && tag.isNotEmpty) {
      _mirrored = _lookup(parsePushNotificationLocaleTag(tag));
    }
  } on Object {
    return;
  }
}

Future<void> writePushNotificationLocale(String tag) async {
  _mirrored = _lookup(parsePushNotificationLocaleTag(tag));
  try {
    await SharedPreferencesAsync().setString(_kPushNotificationLocaleKey, tag);
  } on Object {
    return;
  }
}

Locale parsePushNotificationLocaleTag(String tag) {
  final List<String> parts = tag.split('-');
  String? script;
  String? country;
  for (final String part in parts.skip(1)) {
    if (part.length == 4) {
      script = part;
    } else {
      country = part;
    }
  }
  return Locale.fromSubtags(
    languageCode: parts.first,
    scriptCode: script,
    countryCode: country,
  );
}

StarLocalizations _lookup(Locale locale) {
  try {
    return lookupStarLocalizations(locale);
  } on Object {
    return lookupStarLocalizations(const Locale('en'));
  }
}
