import 'dart:ui' show Locale;

import 'package:flutter_test/flutter_test.dart';
import 'package:star_app/l10n/generated/star_localizations.dart';

export 'package:star_app/l10n/star_localizations_delegates.dart';
export 'package:star_app/l10n/generated/star_localizations.dart';

const Locale kTestLocale = Locale('en');

StarLocalizations get testL10n => lookupStarLocalizations(kTestLocale);

Finder findTestText(String text) => find.text(text);

String testSettingsSwitchSemanticsLabel({
  required String label,
  required String description,
}) => '$label. $description';
