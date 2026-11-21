import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:star_app/core/api/star_client_provider.dart';
import 'package:star_app/core/instance/instance_runtime_config.dart';
import 'package:star_app/core/providers/instance/instance_runtime_config_provider.dart';
import 'package:star_app/core/theme/star_layout_theme.dart';
import 'package:star_app/core/theme/star_text_theme.dart';
import 'package:star_app/core/theme/star_theme.dart';
import 'package:star_app/core/theme/themes/dark.dart';
import 'package:star_app/features/settings/presentation/widgets/user_applications.dart';
import 'package:star_app/features/settings/providers/view_models/user_settings_view_model.dart';
import 'package:star_app/features/ui/button/star_button.dart';
import 'package:star_app/features/ui/spinner/star_loading_spinner.dart';
import 'package:star_app/features/ui/tooltip/star_tooltip.dart';
import 'package:star_app/material_ui.dart';
import 'package:star_dart/export.dart';

import '../../helpers/test_l10n.dart';

class _FakeOAuth2Api implements OAuth2Api {
  _FakeOAuth2Api({this.listError});

  Object? listError;

  @override
  Future<List<ApplicationResponse>> listUserApplications() async {
    if (listError != null) {
      // ignore: only_throw_errors -- test helper rethrows arbitrary objects
      throw listError!;
    }
    return const <ApplicationResponse>[];
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeClient extends StarClient {
  _FakeClient(this._oauth) : super(Dio());

  final OAuth2Api _oauth;

  @override
  OAuth2Api get oAuth2 => _oauth;
}

class _FakeUserSettings extends UserSettingsViewModel {
  _FakeUserSettings({required this.unclaimed});

  final bool unclaimed;

  @override
  UserSettingsViewState build() => UserSettingsViewState(
    userId: 'u1',
    username: 'tester',
    displayName: 'Tester',
    discriminator: '0',
    avatar: null,
    avatarColor: null,
    memberSince: null,
    status: 'online',
    messageDisplayCompact: false,
    developerMode: false,
    trustedDomains: const <String>[],
    isProfileLoaded: true,
    email: unclaimed ? null : 'tester@example.com',
  );
}

Future<void> _pumpWrapped(
  WidgetTester tester,
  Widget child, {
  required OAuth2Api api,
  bool unclaimed = false,
}) {
  final colorTheme = buildDarkColorTheme();
  return tester.pumpWidget(
    ProviderScope(
      overrides: [
        starClientProvider.overrideWithValue(_FakeClient(api)),
        instanceRuntimeConfigProvider.overrideWithValue(
          InstanceRuntimeConfig.defaults,
        ),
        userSettingsViewModelProvider.overrideWith(
          () => _FakeUserSettings(unclaimed: unclaimed),
        ),
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
    ),
  );
}

void main() {
  testWidgets('shows empty state after a successful load', (tester) async {
    await _pumpWrapped(tester, const UserApplications(), api: _FakeOAuth2Api());
    await tester.pumpAndSettle();

    expect(find.text(testL10n.applicationsEmptyTitle), findsOneWidget);
    expect(
      find.text(
        testL10n.applicationsEmptyDescription(
          '${InstanceRuntimeConfig.defaults.productName} API',
        ),
      ),
      findsOneWidget,
    );
  });

  testWidgets('shows load error with retry after failure', (tester) async {
    final api = _FakeOAuth2Api(
      listError: DioException(requestOptions: RequestOptions()),
    );
    await _pumpWrapped(tester, const UserApplications(), api: api);
    await tester.pumpAndSettle();

    expect(find.text(testL10n.applicationsLoadError), findsOneWidget);
    expect(
      find.text(testL10n.applicationsLoadErrorDescription),
      findsOneWidget,
    );
    expect(find.text(testL10n.retry), findsOneWidget);
    expect(find.byType(StarLoadingSpinner), findsNothing);

    api.listError = null;
    await tester.tap(find.text(testL10n.retry));
    await tester.pumpAndSettle();

    expect(find.text(testL10n.applicationsEmptyTitle), findsOneWidget);
  });

  testWidgets('disables create when the account is unclaimed', (tester) async {
    await _pumpWrapped(
      tester,
      const UserApplications(),
      api: _FakeOAuth2Api(),
      unclaimed: true,
    );
    await tester.pumpAndSettle();

    final StarButton button = tester.widget<StarButton>(
      find.widgetWithText(StarButton, testL10n.applicationsCreate),
    );
    expect(button.onPressed, isNull);
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is StarTooltip &&
            widget.message == testL10n.applicationsCreateClaimTooltip,
      ),
      findsOneWidget,
    );
  });
}
