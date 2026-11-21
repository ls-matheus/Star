// Root ProviderScope built by a helper; the lint only exempts a
// ProviderScope written inline in pumpWidget.
// ignore_for_file: riverpod_lint/scoped_providers_should_specify_dependencies

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:star_app/core/theme/star_layout_theme.dart';
import 'package:star_app/core/theme/star_text_theme.dart';
import 'package:star_app/core/theme/star_theme.dart';
import 'package:star_app/core/theme/themes/dark.dart';
import 'package:star_app/features/settings/presentation/widgets/user_accessibility_tts_section.dart';
import 'package:star_app/features/settings/providers/preferences/appearance_preferences_provider.dart';
import 'package:star_app/features/ui/ui.dart';
import 'package:star_app/material_ui.dart';

import '../../helpers/test_l10n.dart';

class _FakeAppearancePreferences extends AppearancePreferences {
  @override
  AppearancePreferencesState build() => const AppearancePreferencesState();

  @override
  Future<void> setTtsRate(double value) async {
    state = state.copyWith(ttsRate: value);
  }
}

Future<ProviderContainer> _pump(WidgetTester tester, Size size) async {
  tester.view
    ..physicalSize = size
    ..devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final container = ProviderContainer(
    overrides: [
      appearancePreferencesProvider.overrideWith(
        _FakeAppearancePreferences.new,
      ),
    ],
  );
  addTearDown(container.dispose);
  final colorTheme = buildDarkColorTheme();
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        locale: kTestLocale,
        localizationsDelegates: starLocalizationsDelegates,
        supportedLocales: StarLocalizations.supportedLocales,
        theme: buildStarTheme(
          colorTheme: colorTheme,
          textTheme: StarTextTheme.fromColors(colorTheme),
          layoutTheme: StarLayoutTheme.scaled(),
        ),
        home: const Scaffold(
          body: SingleChildScrollView(child: UserAccessibilityTtsSection()),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return container;
}

void main() {
  final StarLocalizations l10n = lookupStarLocalizations(kTestLocale);

  testWidgets('phone speed field opens the picker from anywhere', (
    tester,
  ) async {
    final container = await _pump(tester, const Size(390, 844));

    expect(find.byType(EditableText), findsNothing);
    final Finder field = find.byType(StarSelect<double>);
    expect(field, findsOneWidget);
    expect(tester.getSize(field).height, greaterThanOrEqualTo(44));

    await tester.tapAt(tester.getTopLeft(field) + const Offset(24, 22));
    await tester.pumpAndSettle();

    expect(tester.testTextInput.isVisible, isFalse);
    expect(
      find.text(l10n.accessibilityTtsSpeechPlaybackSpeedLabel),
      findsNWidgets(2),
    );

    await tester.tap(find.text('x1.5').last);
    await tester.pumpAndSettle();

    expect(container.read(appearancePreferencesProvider).ttsRate, 1.5);
    expect(find.text('x1.5'), findsOneWidget);
  });

  testWidgets('desktop speed field keeps inline editing', (tester) async {
    await _pump(tester, const Size(1400, 1100));

    expect(find.byType(StarSelect<double>), findsNothing);
    expect(find.byType(EditableText), findsOneWidget);
  });
}
