import 'package:flutter_test/flutter_test.dart';
import 'package:star_app/core/theme/star_color_theme.dart';
import 'package:star_app/core/theme/star_layout_theme.dart';
import 'package:star_app/core/theme/star_text_theme.dart';
import 'package:star_app/core/theme/star_theme.dart';
import 'package:star_app/core/theme/themes/coal.dart';
import 'package:star_app/core/theme/themes/dark.dart';
import 'package:star_app/core/theme/themes/dark_legacy.dart';
import 'package:star_app/core/theme/themes/light.dart';
import 'package:star_app/features/guilds/presentation/widgets/guild_navbar.dart';
import 'package:star_app/material_ui.dart';

final Map<String, StarColorTheme Function()> _themes =
    <String, StarColorTheme Function()>{
      'dark': buildDarkColorTheme,
      'coal': buildCoalColorTheme,
      'dark_legacy': buildDarkLegacyColorTheme,
      'light': buildLightColorTheme,
    };

Widget _host(StarColorTheme colors, Widget child) {
  return MaterialApp(
    theme: buildStarTheme(
      colorTheme: colors,
      textTheme: StarTextTheme.fromColors(colors),
      layoutTheme: StarLayoutTheme.scaled(),
    ),
    home: Scaffold(
      body: Align(alignment: Alignment.topLeft, child: child),
    ),
  );
}

void main() {
  for (final MapEntry<String, StarColorTheme Function()> theme
      in _themes.entries) {
    testWidgets('${theme.key}: icon is a circle that morphs to a rounded '
        'square when active', (tester) async {
      final StarColorTheme colors = theme.value();
      for (final bool isActive in <bool>[false, true]) {
        await tester.pumpWidget(
          _host(
            colors,
            GuildNavbarIconShape(
              isActive: isActive,
              child: const SizedBox.shrink(),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(
          tester.getSize(find.byType(GuildNavbarIconShape)),
          const Size.square(GuildNavbarIconShape.size),
        );
        final ClipRRect clip = tester.widget<ClipRRect>(find.byType(ClipRRect));
        expect(
          clip.borderRadius,
          BorderRadius.circular(
            isActive
                ? GuildNavbarIconShape.activeRadius
                : GuildNavbarIconShape.idleRadius,
          ),
        );
        final ColoredBox fill = tester.widget<ColoredBox>(
          find.descendant(
            of: find.byType(GuildNavbarIconShape),
            matching: find.byType(ColoredBox),
          ),
        );
        expect(
          fill.color,
          isActive ? colors.brandPrimary : colors.serverIconBackground,
        );
      }
    });

    testWidgets('${theme.key}: pill is 4pt wide in primary text colour', (
      tester,
    ) async {
      final StarColorTheme colors = theme.value();
      for (final double height in <double>[
        GuildNavbarPill.unreadHeight,
        GuildNavbarPill.hoverHeight,
        GuildNavbarPill.selectedHeight,
      ]) {
        await tester.pumpWidget(_host(colors, GuildNavbarPill(height: height)));

        expect(
          tester.getSize(find.byType(GuildNavbarPill)),
          Size(GuildNavbarPill.width, height),
        );
        final DecoratedBox box = tester.widget<DecoratedBox>(
          find.descendant(
            of: find.byType(GuildNavbarPill),
            matching: find.byType(DecoratedBox),
          ),
        );
        expect((box.decoration as BoxDecoration).color, colors.textPrimary);
      }
    });
  }

  testWidgets('pill renders nothing at zero height', (tester) async {
    await tester.pumpWidget(
      _host(buildDarkColorTheme(), const GuildNavbarPill(height: 0)),
    );

    expect(tester.getSize(find.byType(GuildNavbarPill)), Size.zero);
  });

  test('rail rows are 56pt apart', () {
    expect(GuildNavbarIconShape.size + GuildNavbarIconShape.itemSpacing, 56);
  });
}
