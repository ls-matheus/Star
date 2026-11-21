import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:star_app/core/router/star_router.dart';
import 'package:star_app/core/theme/star_layout_theme.dart';
import 'package:star_app/core/theme/star_text_theme.dart';
import 'package:star_app/core/theme/star_theme.dart';
import 'package:star_app/core/theme/themes/dark.dart';
import 'package:star_app/material_ui.dart';
import 'package:riverpod/src/framework.dart' show Override;

import 'core_test_provider_overrides.dart';
import 'instance_runtime_config_override.dart';
import 'message_item_test_overrides.dart';
import 'test_account_user_id.dart';
import 'test_l10n.dart';

Widget pumpStarApp({
  required Widget child,
  List<Override> overrides = const [],
  Locale locale = kTestLocale,
  ThemeData? theme,
  bool disableAnimations = true,
  Duration? Function(int retryCount, Object error)? retry,
}) {
  final colorTheme = buildDarkColorTheme();
  return ProviderScope(
    retry: retry,
    overrides: mergeProviderOverrides(<Override>[
      instanceRuntimeConfigOverride(),
      currentUserIdProvider.overrideWithValue(kTestAccountUserId),
      ...messageItemTestProviderOverrides(),
      ...overrides,
    ]),
    child: MaterialApp(
      locale: locale,
      localizationsDelegates: starLocalizationsDelegates,
      supportedLocales: StarLocalizations.supportedLocales,
      theme:
          theme ??
          buildStarTheme(
            colorTheme: colorTheme,
            textTheme: StarTextTheme.fromColors(colorTheme),
            layoutTheme: StarLayoutTheme.scaled(),
          ),
      home: MediaQuery(
        data: MediaQueryData(disableAnimations: disableAnimations),
        child: child,
      ),
    ),
  );
}

Future<void> pumpStarFrames(
  WidgetTester tester, {
  Duration step = const Duration(milliseconds: 100),
  Duration timeout = const Duration(seconds: 3),
}) async {
  await tester.pumpAndSettle(step, EnginePhase.sendSemanticsUpdate, timeout);
}

Future<void> pumpStarFramesQuick(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));
}
