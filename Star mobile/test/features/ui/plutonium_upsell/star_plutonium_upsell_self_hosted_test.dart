// Root ProviderScope built by a helper; the lint only exempts a
// ProviderScope written inline in pumpWidget.
// ignore_for_file: riverpod_lint/scoped_providers_should_specify_dependencies

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:star_app/core/instance/instance_runtime_config.dart';
import 'package:star_app/core/providers/instance/instance_runtime_config_provider.dart';
import 'package:star_app/core/theme/star_layout_theme.dart';
import 'package:star_app/core/theme/star_text_theme.dart';
import 'package:star_app/core/theme/star_theme.dart';
import 'package:star_app/core/theme/themes/dark.dart';
import 'package:star_app/features/ui/plutonium_upsell/star_plutonium_upsell.dart';
import 'package:star_app/material_ui.dart';

import '../../../helpers/test_l10n.dart';

const InstanceRuntimeConfig _selfHostedPremium = InstanceRuntimeConfig(
  productName: 'Acme',
  premiumProductName: 'Premium',
  selfHosted: true,
  premiumEnabled: true,
  stripeEnabled: true,
  emailsEnabled: true,
  voiceEnabled: true,
  presignedAttachmentUploads: true,
  gifEnabled: true,
  blueskyEnabled: true,
  gifAttributionRequired: false,
  singleCommunity: false,
  directMessagesDisabled: false,
  registrationClosed: false,
  adminRegistrationUrlsEnabled: false,
  collectDateOfBirth: true,
);

Widget _app(InstanceRuntimeConfig config) {
  final colorTheme = buildDarkColorTheme();
  return ProviderScope(
    overrides: [instanceRuntimeConfigProvider.overrideWithValue(config)],
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
        body: StarPlutoniumUpsell(text: 'Upgrade for more'),
      ),
    ),
  );
}

void main() {
  for (final TargetPlatform platform in <TargetPlatform>[
    TargetPlatform.iOS,
    TargetPlatform.android,
  ]) {
    testWidgets('hides the upsell on a self-hosted instance with premium '
        'enabled on ${platform.name}', (tester) async {
      debugDefaultTargetPlatformOverride = platform;
      addTearDown(() => debugDefaultTargetPlatformOverride = null);

      await tester.pumpWidget(_app(_selfHostedPremium));

      expect(find.text('Upgrade for more'), findsNothing);
      debugDefaultTargetPlatformOverride = null;
    });
  }

  testWidgets('shows the upsell on the official instance', (tester) async {
    await tester.pumpWidget(_app(InstanceRuntimeConfig.defaults));

    expect(find.text('Upgrade for more'), findsOneWidget);
  });
}
