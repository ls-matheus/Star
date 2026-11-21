import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:star_app/core/platform/star_platform.dart';
import 'package:star_app/core/theme/star_layout_theme.dart';
import 'package:star_app/core/theme/star_text_theme.dart';
import 'package:star_app/core/theme/star_theme.dart';
import 'package:star_app/core/theme/themes/dark.dart';
import 'package:star_app/features/settings/domain/default_web_browser.dart';
import 'package:star_app/features/settings/presentation/widgets/user_default_apps.dart';
import 'package:star_app/features/settings/providers/preferences/default_apps_preferences_provider.dart';
import 'package:star_app/features/settings/utils/default_web_browser_l10n.dart';
import 'package:star_app/material_ui.dart';

import '../../helpers/test_l10n.dart';

class _FakeDefaultAppsPreferences extends DefaultAppsPreferences {
  @override
  DefaultWebBrowser build() => DefaultWebBrowser.inApp;

  @override
  Future<void> setDefaultWebBrowser(DefaultWebBrowser value) async {
    state = value;
  }
}

Widget _wrap(Widget child, {required ProviderContainer container}) {
  final colorTheme = buildDarkColorTheme();
  return UncontrolledProviderScope(
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
      home: Scaffold(body: child),
    ),
  );
}

void main() {
  testWidgets('shows browser options and native app note', (tester) async {
    if (!isStarNativeMobileOs) {
      return;
    }
    final container = ProviderContainer(
      overrides: [
        defaultAppsPreferencesProvider.overrideWith(
          _FakeDefaultAppsPreferences.new,
        ),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      _wrap(const UserDefaultApps(), container: container),
    );
    await tester.pumpAndSettle();

    final l10n = testL10n;
    for (final DefaultWebBrowser browser in availableDefaultWebBrowsers()) {
      expect(find.text(defaultWebBrowserLabel(l10n, browser)), findsOneWidget);
    }

    expect(find.text(l10n.defaultAppsWebBrowserNativeAppNote), findsOneWidget);
  });

  testWidgets('selecting a browser updates preferences', (tester) async {
    if (!isStarNativeMobileOs) {
      return;
    }
    final container = ProviderContainer(
      overrides: [
        defaultAppsPreferencesProvider.overrideWith(
          _FakeDefaultAppsPreferences.new,
        ),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      _wrap(const UserDefaultApps(), container: container),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Qwant'));
    await tester.pumpAndSettle();

    expect(
      container.read(defaultAppsPreferencesProvider),
      DefaultWebBrowser.qwant,
    );
  });
}
