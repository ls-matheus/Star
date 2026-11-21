import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:star_app/core/theme/star_color_theme.dart';
import 'package:star_app/core/theme/star_layout_theme.dart';
import 'package:star_app/core/theme/star_text_theme.dart';
import 'package:star_app/core/theme/star_theme.dart';
import 'package:star_app/core/theme/themes/coal.dart';
import 'package:star_app/core/theme/themes/dark.dart';
import 'package:star_app/core/theme/themes/light.dart';
import 'package:star_app/features/ui/radio_group/star_radio_group.dart';
import 'package:star_app/material_ui.dart';

double _contrast(Color a, Color b) {
  final double x = a.computeLuminance();
  final double y = b.computeLuminance();
  return (math.max(x, y) + 0.05) / (math.min(x, y) + 0.05);
}

void main() {
  for (final (String name, StarColorTheme colors, Brightness brightness)
      in <(String, StarColorTheme, Brightness)>[
        ('dark', buildDarkColorTheme(), Brightness.dark),
        ('coal', buildCoalColorTheme(), Brightness.dark),
        ('light', buildLightColorTheme(), Brightness.light),
      ]) {
    testWidgets('the unselected ring keeps 3:1 contrast in $name', (
      WidgetTester tester,
    ) async {
      late Color ring;
      await tester.pumpWidget(
        MaterialApp(
          theme: buildStarTheme(
            colorTheme: colors,
            textTheme: StarTextTheme.fromColors(colors),
            layoutTheme: StarLayoutTheme.scaled(),
            brightness: brightness,
          ),
          home: Builder(
            builder: (BuildContext context) {
              ring = starRadioRingColor(context);
              return const SizedBox.shrink();
            },
          ),
        ),
      );
      for (final Color surface in <Color>[
        colors.backgroundPrimary,
        colors.backgroundSecondary,
        colors.backgroundSecondaryAlt,
        colors.backgroundTertiary,
      ]) {
        expect(
          _contrast(Color.alphaBlend(ring, surface), surface),
          greaterThanOrEqualTo(3),
        );
      }
    });
  }
}
