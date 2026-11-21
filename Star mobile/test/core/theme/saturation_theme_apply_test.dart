import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:star_app/core/theme/star_color_theme.dart';
import 'package:star_app/core/theme/star_layout_theme.dart';
import 'package:star_app/core/theme/star_theme.dart';
import 'package:star_app/core/theme/star_theme_mode.dart';
import 'package:star_app/core/theme/providers/theme_preference_provider.dart';
import 'package:star_app/material_ui.dart';

void main() {
  testWidgets('saturation factor updates MaterialApp theme extension', (
    tester,
  ) async {
    await tester.pumpWidget(const ProviderScope(child: _SaturationHost()));
    await tester.pumpAndSettle();

    final BuildContext context = tester.element(find.byType(Scaffold));
    final Color before = Theme.of(
      context,
    ).extension<StarColorTheme>()!.brandPrimary;

    await tester.tap(find.text('desaturate'));
    await tester.pumpAndSettle();

    final Color after = Theme.of(
      context,
    ).extension<StarColorTheme>()!.brandPrimary;
    expect(after, isNot(before));
    expect(after.toARGB32(), const Color(0xFF8C8C8C).toARGB32());
  });

  testWidgets('previewSaturationFactor updates theme live', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: _SaturationHost()));
    await tester.pump();

    final container = ProviderScope.containerOf(
      tester.element(find.byType(Scaffold)),
    );
    final Color before = container
        .read(themePreferenceProvider)
        .colorTheme
        .brandPrimary;

    container.read(themePreferenceProvider.notifier).previewSaturationFactor(0);
    await tester.pump();

    final Color after = container
        .read(themePreferenceProvider)
        .colorTheme
        .brandPrimary;
    expect(after, isNot(before));
    expect(
      Theme.of(
        tester.element(find.byType(Scaffold)),
      ).extension<StarColorTheme>()!.brandPrimary.toARGB32(),
      after.toARGB32(),
    );
  });
}

class _SaturationHost extends ConsumerWidget {
  const _SaturationHost();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themePref = ref.watch(themePreferenceProvider);
    final theme = buildStarTheme(
      colorTheme: themePref.colorTheme,
      textTheme: themePref.textTheme,
      layoutTheme: StarLayoutTheme.scaled(),
      brightness: themePref.mode == StarThemeMode.light
          ? Brightness.light
          : Brightness.dark,
    );
    return MaterialApp(
      theme: theme,
      themeMode: ThemeMode.dark,
      darkTheme: theme,
      themeAnimationDuration: Duration.zero,
      home: Scaffold(
        body: Column(
          children: [
            Text('brand:${themePref.colorTheme.brandPrimary.toARGB32()}'),
            TextButton(
              onPressed: () {
                unawaited(
                  ref
                      .read(themePreferenceProvider.notifier)
                      .setSaturationFactor(0),
                );
              },
              child: const Text('desaturate'),
            ),
          ],
        ),
      ),
    );
  }
}
