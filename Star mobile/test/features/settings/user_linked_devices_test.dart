import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:star_app/core/api/star_client_provider.dart';
import 'package:star_app/core/theme/star_layout_theme.dart';
import 'package:star_app/core/theme/star_text_theme.dart';
import 'package:star_app/core/theme/star_theme.dart';
import 'package:star_app/core/theme/themes/dark.dart';
import 'package:star_app/features/auth/providers/current_auth_session_provider.dart';
import 'package:star_app/features/settings/presentation/widgets/user_linked_devices.dart';
import 'package:star_app/features/ui/spinner/star_loading_spinner.dart';
import 'package:star_app/l10n/star_localizations_delegates.dart';
import 'package:star_app/l10n/generated/star_localizations.dart';
import 'package:star_app/material_ui.dart';
import 'package:star_dart/export.dart';

class _FakeAuthApi implements AuthApi {
  _FakeAuthApi({this.sessions = const [], this.listError});
  List<AuthSessionResponse> sessions;
  Object? listError;

  @override
  Future<AuthSessionsResponse> listAuthSessions() async {
    if (listError != null) {
      // ignore: only_throw_errors -- test helper rethrows arbitrary objects to simulate network failures
      throw listError!;
    }
    return sessions;
  }

  @override
  Future<void> logoutAllSessions({
    required LogoutAuthSessionsWithVerificationRequest body,
  }) async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeClient extends StarClient {
  _FakeClient(this._fakeAuth) : super(Dio());

  final AuthApi _fakeAuth;

  @override
  AuthApi get auth => _fakeAuth;
}

Widget _wrap(Widget child, {required AuthApi api, String? currentIdHash}) {
  final colorTheme = buildDarkColorTheme();
  final container = ProviderContainer(
    overrides: [starClientProvider.overrideWithValue(_FakeClient(api))],
  );
  if (currentIdHash != null) {
    container
        .read(currentAuthSessionIdHashProvider.notifier)
        .update(currentIdHash);
  }
  return UncontrolledProviderScope(
    container: container,
    child: MaterialApp(
      theme: buildStarTheme(
        colorTheme: colorTheme,
        textTheme: StarTextTheme.fromColors(colorTheme),
        layoutTheme: StarLayoutTheme.scaled(),
      ),
      localizationsDelegates: starLocalizationsDelegates,
      supportedLocales: StarLocalizations.supportedLocales,
      home: Scaffold(body: child),
    ),
  );
}

AuthSessionResponse _session({
  required String id,
  bool current = false,
  String os = 'macOS',
  String platform = 'Star Desktop',
  String? browser,
  String? maskedIp,
  AuthSessionLocation? location,
  AuthSessionResponseClientInfoDeviceDevice device =
      AuthSessionResponseClientInfoDeviceDevice.desktop,
}) {
  return AuthSessionResponse(
    idHash: id,
    maskedIp: maskedIp,
    current: current,
    clientInfo: AuthSessionResponseClientInfo(
      device: device,
      os: os,
      platform: platform,
      browser: browser,
      location: location,
    ),
    approxLastUsedAt: DateTime.now().subtract(const Duration(hours: 2)),
  );
}

void main() {
  testWidgets('shows loading spinner initially', (tester) async {
    await tester.pumpWidget(
      _wrap(
        const UserLinkedDevices(),
        api: _FakeAuthApi(sessions: [_session(id: 'a')]),
        currentIdHash: 'a',
      ),
    );
    expect(find.byType(StarLoadingSpinner), findsOneWidget);
  });

  testWidgets('shows load error with retry after failure', (tester) async {
    final api = _FakeAuthApi(
      listError: DioException(requestOptions: RequestOptions()),
    );
    await tester.pumpWidget(_wrap(const UserLinkedDevices(), api: api));
    await tester.pumpAndSettle();

    expect(find.text('Network error'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
  });

  testWidgets('renders current-only device list without bulk button', (
    tester,
  ) async {
    final api = _FakeAuthApi(sessions: [_session(id: 'a')]);
    await tester.pumpWidget(
      _wrap(const UserLinkedDevices(), api: api, currentIdHash: 'a'),
    );
    await tester.pumpAndSettle();

    expect(find.text('Current device'), findsOneWidget);
    expect(find.text('Other devices'), findsNothing);
    expect(find.text('Sign out all other devices'), findsNothing);
  });

  testWidgets('renders both sections and bulk button with multiple sessions', (
    tester,
  ) async {
    final api = _FakeAuthApi(
      sessions: [
        _session(id: 'a'),
        _session(id: 'b'),
        _session(id: 'c', os: 'iOS'),
      ],
    );
    await tester.pumpWidget(
      _wrap(const UserLinkedDevices(), api: api, currentIdHash: 'a'),
    );
    await tester.pumpAndSettle();

    expect(find.text('Current device'), findsOneWidget);
    expect(find.text('Other devices'), findsOneWidget);
    expect(find.text('Sign out all other devices'), findsOneWidget);
  });

  testWidgets('hides bulk button when only one other device exists', (
    tester,
  ) async {
    final api = _FakeAuthApi(
      sessions: [
        _session(id: 'a'),
        _session(id: 'b'),
      ],
    );
    await tester.pumpWidget(
      _wrap(const UserLinkedDevices(), api: api, currentIdHash: 'a'),
    );
    await tester.pumpAndSettle();

    expect(find.text('Other devices'), findsOneWidget);
    expect(find.text('Sign out all other devices'), findsNothing);
  });

  testWidgets('shows Network Error when current session cannot be identified', (
    tester,
  ) async {
    final api = _FakeAuthApi(
      sessions: [
        _session(id: 'a'),
        _session(id: 'b'),
        _session(id: 'c'),
      ],
    );
    await tester.pumpWidget(_wrap(const UserLinkedDevices(), api: api));
    await tester.pumpAndSettle();

    expect(find.text('Network error'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
    expect(find.text('Current device'), findsNothing);
    expect(find.text('Other devices'), findsNothing);
    expect(find.text('Sign out all other devices'), findsNothing);
  });

  testWidgets('identifies current session via gateway-supplied id hash', (
    tester,
  ) async {
    final api = _FakeAuthApi(
      sessions: [
        _session(id: 'a'),
        _session(id: 'b'),
        _session(id: 'c'),
      ],
    );
    await tester.pumpWidget(
      _wrap(const UserLinkedDevices(), api: api, currentIdHash: 'b'),
    );
    await tester.pumpAndSettle();

    expect(find.text('Current device'), findsOneWidget);
    expect(find.text('Other devices'), findsOneWidget);
  });

  testWidgets('shows platform only for native clients without browser', (
    tester,
  ) async {
    final api = _FakeAuthApi(
      sessions: [_session(id: 'a', platform: 'Star macOS')],
    );
    await tester.pumpWidget(
      _wrap(const UserLinkedDevices(), api: api, currentIdHash: 'a'),
    );
    await tester.pumpAndSettle();

    expect(find.text('Star macOS'), findsOneWidget);
    expect(find.text('macOS'), findsNothing);
  });

  testWidgets('shows os and platform for web browser sessions', (tester) async {
    final api = _FakeAuthApi(
      sessions: [
        _session(id: 'a', platform: 'Chrome', browser: 'Chrome'),
        _session(id: 'b', platform: 'Chrome', browser: 'Chrome'),
      ],
    );
    await tester.pumpWidget(
      _wrap(const UserLinkedDevices(), api: api, currentIdHash: 'a'),
    );
    await tester.pumpAndSettle();

    expect(find.text('macOS · Chrome'), findsNWidgets(2));
  });

  testWidgets('shows info button on current and other devices', (tester) async {
    final api = _FakeAuthApi(
      sessions: [
        _session(id: 'a'),
        _session(id: 'b'),
      ],
    );
    await tester.pumpWidget(
      _wrap(const UserLinkedDevices(), api: api, currentIdHash: 'a'),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('View details')), findsNWidgets(2));
  });

  testWidgets('opens device details with extra session fields', (tester) async {
    final api = _FakeAuthApi(
      sessions: [
        _session(
          id: 'a',
          maskedIp: '12.34.***.***',
          location: const AuthSessionLocation(
            city: 'Berlin',
            country: 'Germany',
          ),
        ),
      ],
    );
    await tester.pumpWidget(
      _wrap(const UserLinkedDevices(), api: api, currentIdHash: 'a'),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('View details')));
    await tester.pumpAndSettle();

    expect(find.text('Device details'), findsOneWidget);
    expect(find.text('Device'), findsOneWidget);
    expect(find.text('Client'), findsOneWidget);
    expect(find.text('Location'), findsOneWidget);
    expect(find.text('Berlin, Germany'), findsOneWidget);
    expect(find.text('IP address'), findsOneWidget);
    expect(find.text('12.34.***.***'), findsOneWidget);
    expect(find.text('Last used'), findsOneWidget);
    expect(find.text('Current session'), findsOneWidget);
    expect(find.text('macOS'), findsOneWidget);
    expect(find.text('Star Desktop'), findsWidgets);
  });

  testWidgets('hides info buttons while selecting other devices', (
    tester,
  ) async {
    final api = _FakeAuthApi(
      sessions: [
        _session(id: 'a'),
        _session(id: 'b'),
        _session(id: 'c'),
      ],
    );
    await tester.pumpWidget(
      _wrap(const UserLinkedDevices(), api: api, currentIdHash: 'a'),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('View details')), findsNWidgets(3));

    await tester.tap(find.byKey(const ValueKey('Enter selection mode')));
    await tester.pump();

    expect(find.byKey(const ValueKey('View details')), findsNothing);
  });
}
