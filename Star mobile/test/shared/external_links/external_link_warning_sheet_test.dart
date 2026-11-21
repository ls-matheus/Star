import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:star_app/core/theme/star_layout_theme.dart';
import 'package:star_app/core/theme/star_text_theme.dart';
import 'package:star_app/core/theme/star_theme.dart';
import 'package:star_app/core/theme/themes/dark.dart';
import 'package:star_app/features/ui/button/star_button.dart';
import 'package:star_app/material_ui.dart';
import 'package:star_app/shared/external_links/external_link_warning_sheet.dart';

import '../../helpers/instance_runtime_config_override.dart';
import '../../helpers/test_l10n.dart';

void main() {
  testWidgets(
    'visit site button keeps a gap above the navigation bar without a system inset',
    (tester) async {
      const Size screenSize = Size(400, 800);
      tester.view.physicalSize = screenSize;
      tester.view.devicePixelRatio = 1;
      tester.view.padding = FakeViewPadding.zero;
      tester.view.viewPadding = FakeViewPadding.zero;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPadding);
      addTearDown(tester.view.resetViewPadding);

      final colorTheme = buildDarkColorTheme();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [instanceRuntimeConfigOverride()],
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
                builder: (context) => ElevatedButton(
                  onPressed: () => unawaited(
                    ExternalLinkWarningSheet.show(
                      context,
                      url: 'https://example.com',
                      hostname: 'example.com',
                      onContinue: ({required bool trustDomain}) async {},
                    ),
                  ),
                  child: const Text('Open'),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      final double buttonBottom = tester
          .getRect(
            find.ancestor(
              of: find.text(testL10n.externalLinkVisitSite),
              matching: find.byType(StarButton),
            ),
          )
          .bottom;
      expect(buttonBottom, lessThanOrEqualTo(screenSize.height - 16));
    },
  );
}
