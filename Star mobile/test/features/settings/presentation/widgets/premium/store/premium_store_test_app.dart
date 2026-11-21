import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:star_app/core/theme/star_layout_theme.dart';
import 'package:star_app/core/theme/star_text_theme.dart';
import 'package:star_app/core/theme/star_theme.dart';
import 'package:star_app/core/theme/themes/dark.dart';
import 'package:star_app/core/theme/themes/light.dart';
import 'package:star_app/features/settings/presentation/widgets/premium/store/premium_store_backdrop.dart';
import 'package:star_app/features/settings/presentation/widgets/premium/store/premium_store_comparison.dart';
import 'package:star_app/features/settings/presentation/widgets/premium/store/premium_store_showcase.dart';
import 'package:star_app/material_ui.dart';

import '../../../../../../helpers/instance_runtime_config_override.dart';
import '../../../../../../helpers/test_l10n.dart';

const Key premiumStoreTestBarKey = Key('premium-store-test-bar');

Widget premiumStoreTestApp({
  required Brightness brightness,
  required ScrollController controller,
}) {
  final colorTheme = brightness == Brightness.light
      ? buildLightColorTheme()
      : buildDarkColorTheme();
  return MaterialApp(
    locale: kTestLocale,
    localizationsDelegates: starLocalizationsDelegates,
    supportedLocales: StarLocalizations.supportedLocales,
    theme: buildStarTheme(
      colorTheme: colorTheme,
      textTheme: StarTextTheme.fromColors(colorTheme),
      layoutTheme: StarLayoutTheme.scaled(),
      brightness: brightness,
    ),
    home: ProviderScope(
      overrides: [instanceRuntimeConfigOverride()],
      child: Scaffold(
        body: PremiumStoreBackdrop(
          bar: const SizedBox(key: premiumStoreTestBarKey, height: 48),
          child: SingleChildScrollView(
            controller: controller,
            padding: const EdgeInsets.all(16),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                PremiumStoreShowcase(),
                SizedBox(height: 16),
                PremiumStoreComparison(),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
