import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:star_app/core/theme/star_layout_theme.dart';
import 'package:star_app/core/theme/star_text_theme.dart';
import 'package:star_app/core/theme/star_theme.dart';
import 'package:star_app/core/theme/themes/dark.dart';
import 'package:star_app/features/settings/presentation/widgets/theme_swatch_button.dart';
import 'package:star_app/features/ui/tooltip/star_tooltip.dart';
import 'package:star_app/material_ui.dart';

Widget _buildTestApp(Widget child) {
  final colorTheme = buildDarkColorTheme();
  return ProviderScope(
    child: MaterialApp(
      theme: buildStarTheme(
        colorTheme: colorTheme,
        textTheme: StarTextTheme.fromColors(colorTheme),
        layoutTheme: StarLayoutTheme.scaled(),
      ),
      home: Scaffold(body: child),
    ),
  );
}

void main() {
  testWidgets('shows theme name on long press', (tester) async {
    await tester.pumpWidget(
      _buildTestApp(
        ThemeSwatchButton(
          label: 'Dark theme',
          backgroundColor: const Color(0xFF1D1C22),
          isSelected: false,
          onTap: () {},
        ),
      ),
    );

    expect(find.text('Dark theme'), findsNothing);

    await tester.longPress(find.byType(ThemeSwatchButton));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Dark theme'), findsOneWidget);
    expect(find.byType(StarTooltip), findsOneWidget);
  });

  testWidgets('exposes theme name as semantics label', (tester) async {
    final SemanticsHandle handle = tester.ensureSemantics();

    await tester.pumpWidget(
      _buildTestApp(
        ThemeSwatchButton(
          label: 'Light theme',
          backgroundColor: const Color(0xFFFBFBFC),
          isSelected: true,
          onTap: () {},
        ),
      ),
    );

    expect(find.bySemanticsLabel('Light theme'), findsOneWidget);
    handle.dispose();
  });
}
