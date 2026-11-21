import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:star_app/core/observability/reporting_consent/observability_reporting_consent_sheet.dart';
import 'package:star_app/core/theme/star_layout_theme.dart';
import 'package:star_app/core/theme/star_text_theme.dart';
import 'package:star_app/core/theme/star_theme.dart';
import 'package:star_app/core/theme/themes/dark.dart';
import 'package:star_app/features/ui/button/star_button.dart';
import 'package:star_app/material_ui.dart';

import '../../../helpers/test_l10n.dart';

const Size _screenSize = Size(400, 800);

Future<({Future<bool?> result})> _openSheet(WidgetTester tester) async {
  tester.view.physicalSize = _screenSize;
  tester.view.devicePixelRatio = 1;
  tester.view.padding = FakeViewPadding.zero;
  tester.view.viewPadding = FakeViewPadding.zero;
  addTearDown(tester.view.reset);

  late BuildContext pageContext;
  final colorTheme = buildDarkColorTheme();
  await tester.pumpWidget(
    ProviderScope(
      child: MaterialApp(
        locale: kTestLocale,
        localizationsDelegates: starLocalizationsDelegates,
        supportedLocales: StarLocalizations.supportedLocales,
        theme: buildStarTheme(
          colorTheme: colorTheme,
          textTheme: StarTextTheme.fromColors(colorTheme),
          layoutTheme: StarLayoutTheme.scaled(),
        ),
        home: Scaffold(
          body: Builder(
            builder: (context) {
              pageContext = context;
              return const SizedBox.expand();
            },
          ),
        ),
      ),
    ),
  );
  final Future<bool?> result = showObservabilityReportingConsentSheet(
    pageContext,
  );
  await tester.pumpAndSettle();
  return (result: result);
}

void main() {
  testWidgets(
    'decline button keeps a gap above the navigation bar without a system inset',
    (tester) async {
      await _openSheet(tester);

      final double buttonBottom = tester
          .getRect(
            find
                .ancestor(
                  of: find.text(testL10n.observabilityReportingConsentDecline),
                  matching: find.byType(StarButton),
                )
                .first,
          )
          .bottom;
      expect(buttonBottom, lessThanOrEqualTo(_screenSize.height - 16));
    },
  );

  testWidgets('not now closes the sheet without a decision', (tester) async {
    final Future<bool?> result = (await _openSheet(tester)).result;

    await tester.tap(find.text(testL10n.observabilityReportingConsentNotNow));
    await tester.pumpAndSettle();

    expect(await result, isNull);
  });

  testWidgets('a scrim tap closes the sheet without a decision', (
    tester,
  ) async {
    final Future<bool?> result = (await _openSheet(tester)).result;

    await tester.tapAt(const Offset(200, 20));
    await tester.pumpAndSettle();

    expect(await result, isNull);
  });
}
