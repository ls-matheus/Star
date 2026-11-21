import 'dart:ui' show Locale;

import 'package:flutter_test/flutter_test.dart';
import 'package:star_app/l10n/generated/star_localizations.dart';

void main() {
  test('community mute copy does not promise mention notifications', () {
    for (final Locale locale in const <Locale>[
      Locale('en'),
      Locale('en', 'US'),
    ]) {
      expect(
        lookupStarLocalizations(locale).notificationMuteDescription,
        'Muting a community hides its unread badge and prevents '
        'notifications from appearing',
      );
    }
  });
}
