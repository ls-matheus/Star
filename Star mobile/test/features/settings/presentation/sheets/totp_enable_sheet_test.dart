// Root ProviderScope built by a helper; the lint only exempts a
// ProviderScope written inline in pumpWidget.
// ignore_for_file: riverpod_lint/scoped_providers_should_specify_dependencies

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:star_app/core/instance/instance_runtime_config.dart';
import 'package:star_app/core/providers/instance/instance_runtime_config_provider.dart';
import 'package:star_app/core/theme/star_layout_theme.dart';
import 'package:star_app/core/theme/star_text_theme.dart';
import 'package:star_app/core/theme/star_theme.dart';
import 'package:star_app/core/theme/themes/dark.dart';
import 'package:star_app/features/settings/presentation/sheets/totp_enable_sheet.dart';
import 'package:star_app/features/settings/providers/view_models/user_settings_view_model.dart';
import 'package:star_app/features/ui/qr_code/star_qr_code.dart';
import 'package:star_app/material_ui.dart';

import '../../../../helpers/test_l10n.dart';

class _FixedUserSettings extends UserSettingsViewModel {
  @override
  UserSettingsViewState build() {
    return const UserSettingsViewState(
      userId: '1',
      username: 'alice',
      displayName: 'Alice',
      discriminator: '0',
      avatar: null,
      avatarColor: null,
      memberSince: null,
      status: 'offline',
      messageDisplayCompact: false,
      developerMode: false,
      trustedDomains: <String>[],
      email: 'alice@example.com',
    );
  }
}

Widget _wrap({required Widget child}) {
  final colorTheme = buildDarkColorTheme();
  return ProviderScope(
    overrides: [
      instanceRuntimeConfigProvider.overrideWithValue(
        InstanceRuntimeConfig.defaults,
      ),
      userSettingsViewModelProvider.overrideWith(_FixedUserSettings.new),
    ],
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
  testWidgets('shows a scannable QR code above the setup secret', (
    tester,
  ) async {
    await tester.pumpWidget(_wrap(child: const TotpEnableSheet()));
    await tester.pumpAndSettle();

    expect(find.byType(StarQrCode), findsOneWidget);
    expect(find.textContaining('scan with authenticator'), findsNothing);

    final StarQrCode qr = tester.widget(find.byType(StarQrCode));
    expect(qr.data, startsWith('otpauth://totp/'));
    expect(qr.data, contains('alice%40example.com'));
    expect(qr.data, contains('secret='));
    expect(qr.data, contains('issuer=Star'));

    final SelectableText secret = tester.widget(find.byType(SelectableText));
    expect(secret.data, hasLength(32));

    expect(
      tester.getTopLeft(find.byType(StarQrCode)).dy,
      lessThan(tester.getTopLeft(find.byType(SelectableText)).dy),
    );
  });
}
