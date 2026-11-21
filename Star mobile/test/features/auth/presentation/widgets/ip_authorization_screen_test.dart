import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:star_app/core/theme/star_layout_theme.dart';
import 'package:star_app/core/theme/star_text_theme.dart';
import 'package:star_app/core/theme/star_theme.dart';
import 'package:star_app/core/theme/themes/dark.dart';
import 'package:star_app/features/auth/data/auth_repository.dart';
import 'package:star_app/features/auth/domain/ip_auth_poll_result.dart';
import 'package:star_app/features/auth/domain/ip_authorization_challenge.dart';
import 'package:star_app/features/auth/presentation/widgets/ip_authorization_screen.dart';
import 'package:star_app/features/auth/providers/auth_providers.dart';
import 'package:star_app/features/ui/button/star_button.dart';
import 'package:star_app/material_ui.dart';

import '../../../../helpers/test_l10n.dart';

class _ExpiredAuthRepository implements AuthRepository {
  @override
  Future<IpAuthPollResult> pollIpAuthorization(String ticket) async =>
      const IpAuthExpired();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Widget _app(Widget child) {
  final colorTheme = buildDarkColorTheme();
  return MaterialApp(
    locale: kTestLocale,
    localizationsDelegates: starLocalizationsDelegates,
    supportedLocales: StarLocalizations.supportedLocales,
    theme: buildStarTheme(
      colorTheme: colorTheme,
      textTheme: StarTextTheme.fromColors(colorTheme),
      layoutTheme: StarLayoutTheme.scaled(),
    ),
    home: Scaffold(body: Center(child: child)),
  );
}

void main() {
  testWidgets('shows a terminal expired state with no retry or resend', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(_ExpiredAuthRepository()),
        ],
        child: _app(
          IpAuthorizationScreen(
            challenge: const IpAuthorizationChallenge(
              ticket: 'ticket',
              email: 'user@example.com',
              resendAvailableIn: 0,
            ),
            onAuthorized: () {},
            onBack: () {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Sign-in link expired'), findsOneWidget);
    expect(find.text('Resend email'), findsNothing);
    expect(find.byType(StarButton), findsOneWidget);
    expect(find.text('Back'), findsOneWidget);
  });
}
