// Root ProviderScope built by a helper; the lint only exempts a
// ProviderScope written inline in pumpWidget.
// ignore_for_file: riverpod_lint/scoped_providers_should_specify_dependencies

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:star_app/core/database/star_database.dart';
import 'package:star_app/core/theme/star_color_theme.dart';
import 'package:star_app/core/theme/star_layout_theme.dart';
import 'package:star_app/core/theme/star_text_theme.dart';
import 'package:star_app/core/theme/star_theme.dart';
import 'package:star_app/core/theme/themes/dark.dart';
import 'package:star_app/features/chat/presentation/widgets/messages/message_markdown.dart';
import 'package:star_app/features/settings/providers/preferences/time_format_providers.dart';
import 'package:star_app/l10n/generated/star_localizations.dart';
import 'package:star_app/material_ui.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';

import '../../../../../helpers/core_test_provider_overrides.dart';
import '../../../../../helpers/open_test_database.dart';
import '../../../../../helpers/rendered_text_test_helpers.dart';

Widget _app({
  required Locale locale,
  required Widget child,
  required StarDatabase database,
  bool use12Hour = false,
}) {
  final StarColorTheme colorTheme = buildDarkColorTheme();
  return ProviderScope(
    key: ValueKey<String>('${locale.toLanguageTag()}-$use12Hour'),
    overrides: coreTestProviderOverrides(
      database: database,
      extra: [use12HourTimeFormatProvider.overrideWithValue(use12Hour)],
    ),
    child: MaterialApp(
      locale: locale,
      localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
        StarLocalizations.delegate,
        ...GlobalMaterialLocalizations.delegates,
      ],
      supportedLocales: StarLocalizations.supportedLocales,
      theme: buildStarTheme(
        colorTheme: colorTheme,
        textTheme: StarTextTheme.fromColors(colorTheme),
        layoutTheme: StarLayoutTheme.scaled(),
      ),
      home: Scaffold(body: child),
    ),
  );
}

List<String> _renderedTexts(WidgetTester tester) =>
    renderedTextContents(tester);

void main() {
  setUpAll(() async {
    await initializeDateFormatting('en_US');
    await initializeDateFormatting('fr');
    await initializeDateFormatting('de');
  });

  testWidgets('timestamp follows app locale when Intl default differs', (
    WidgetTester tester,
  ) async {
    final String? previousDefaultLocale = Intl.defaultLocale;
    Intl.defaultLocale = 'de';
    addTearDown(() => Intl.defaultLocale = previousDefaultLocale);
    final DateTime dateTime = DateTime(2026, 7, 20, 16, 5);
    final int unix = dateTime.millisecondsSinceEpoch ~/ 1000;
    final String french = DateFormat.yMMMMd('fr').format(dateTime);
    final String german = DateFormat.yMMMMd('de').format(dateTime);
    expect(french, isNot(german));

    final StarDatabase database = openTestDatabase();
    await tester.pumpWidget(
      _app(
        locale: const Locale('fr'),
        database: database,
        child: MessageMarkdown(
          data: '<t:$unix:D>',
          baseStyle: const TextStyle(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(_renderedTexts(tester), contains(french));
    expect(_renderedTexts(tester), isNot(contains(german)));

    await tester.pumpWidget(
      _app(
        locale: const Locale('de'),
        database: database,
        child: MessageMarkdown(
          data: '<t:$unix:D>',
          baseStyle: const TextStyle(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(_renderedTexts(tester), contains(german));
    await releaseTestWidgetTree(tester);
  });

  testWidgets('timestamp follows the user hour-cycle preference', (
    WidgetTester tester,
  ) async {
    final DateTime dateTime = DateTime(2026, 7, 20, 16, 5);
    final int unix = dateTime.millisecondsSinceEpoch ~/ 1000;
    final StarDatabase database = openTestDatabase();

    await tester.pumpWidget(
      _app(
        locale: const Locale('en', 'US'),
        database: database,
        use12Hour: true,
        child: MessageMarkdown(
          data: '<t:$unix:t>',
          baseStyle: const TextStyle(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      _renderedTexts(
        tester,
      ).map((String text) => text.replaceAll('\u202f', ' ')),
      contains('4:05 PM'),
    );

    await tester.pumpWidget(
      _app(
        locale: const Locale('en', 'US'),
        database: database,
        child: MessageMarkdown(
          data: '<t:$unix:t>',
          baseStyle: const TextStyle(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(_renderedTexts(tester), contains('16:05'));
    await releaseTestWidgetTree(tester);
  });
}
