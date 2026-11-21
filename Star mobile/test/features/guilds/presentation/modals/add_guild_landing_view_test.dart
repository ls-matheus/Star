import 'package:flutter_test/flutter_test.dart';
import 'package:star_app/core/platform/star_platform.dart';
import 'package:star_app/core/theme/star_layout_theme.dart';
import 'package:star_app/core/theme/star_text_theme.dart';
import 'package:star_app/core/theme/star_theme.dart';
import 'package:star_app/core/theme/themes/dark.dart';
import 'package:star_app/features/guilds/presentation/modals/add_guild_action_button.dart';
import 'package:star_app/features/guilds/presentation/modals/add_guild_landing_view.dart';
import 'package:star_app/material_ui.dart';

import '../../../../helpers/test_l10n.dart';

void main() {
  testWidgets('landing options sit on cards that stand out from the page', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(402 * 3, 874 * 3);
    tester.view.devicePixelRatio = 3;
    debugSetStarRuntimeMobileFormFactor(value: true);
    addTearDown(() {
      tester.view.reset();
      debugSetStarRuntimeMobileFormFactor(value: null);
    });
    final colorTheme = buildDarkColorTheme();
    await tester.pumpWidget(
      MaterialApp(
        locale: kTestLocale,
        localizationsDelegates: starLocalizationsDelegates,
        supportedLocales: StarLocalizations.supportedLocales,
        theme: buildStarTheme(
          colorTheme: colorTheme,
          textTheme: StarTextTheme.fromColors(colorTheme),
          layoutTheme: StarLayoutTheme.scaled(),
        ),
        home: Scaffold(
          backgroundColor: colorTheme.backgroundSecondary,
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: AddGuildLandingView(
              onCreateTap: () {},
              onJoinTap: () {},
              onImportTap: () {},
            ),
          ),
        ),
      ),
    );

    final List<BoxDecoration> cards = tester
        .widgetList<AnimatedContainer>(
          find.descendant(
            of: find.byType(AddGuildActionButton),
            matching: find.byType(AnimatedContainer),
          ),
        )
        .map((AnimatedContainer c) => c.decoration! as BoxDecoration)
        .toList();
    expect(cards, hasLength(3));
    for (final BoxDecoration card in cards) {
      expect(card.color, isNot(colorTheme.backgroundSecondary));
      expect(card.color, cards.first.color);
      expect(card.borderRadius, cards.first.borderRadius);
    }
  });
}
