import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:star_app/core/api/star_client_provider.dart';
import 'package:star_app/core/router/star_router.dart';
import 'package:star_app/features/settings/providers/view_models/webauthn_credentials_view_model.dart';
import 'package:star_dart/export.dart';

class _FakeUsersApi implements UsersApi {
  _FakeUsersApi({this.credentials = const [], this.listError, this.onList});

  List<WebAuthnCredentialResponse> credentials;
  Object? listError;
  Future<List<WebAuthnCredentialResponse>> Function()? onList;

  @override
  Future<List<WebAuthnCredentialResponse>> listWebauthnCredentials() async {
    final onList = this.onList;
    if (onList != null) {
      return await onList();
    }
    if (listError != null) {
      // Test fake: re-throw whatever the test supplied (e.g. DioException).
      // ignore: only_throw_errors
      throw listError!;
    }
    return credentials;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeClient extends StarClient {
  _FakeClient(this._fakeUsers) : super(Dio());

  final UsersApi _fakeUsers;

  @override
  UsersApi get users => _fakeUsers;
}

WebAuthnCredentialResponse _cred({
  required String id,
  String name = 'Key',
  String rpId = 'star.invalid',
}) {
  return WebAuthnCredentialResponse(
    id: id,
    name: name,
    createdAt: '2026-01-01T00:00:00Z',
    lastUsedAt: null,
    rpId: rpId,
  );
}

const _testUserId = 'test-user';

ProviderContainer _container(UsersApi api) {
  final client = _FakeClient(api);
  final container = ProviderContainer(
    overrides: [starClientProvider.overrideWithValue(client)],
  );
  container.read(currentUserIdProvider.notifier).set(_testUserId);
  return container;
}

Future<void> _pumpMicrotasks() async {
  await Future<void>.delayed(Duration.zero);
  await Future<void>.delayed(Duration.zero);
}

void main() {
  group('WebauthnCredentialsViewModel', () {
    test('build hydrates credentials from REST', () async {
      final api = _FakeUsersApi(
        credentials: [
          _cred(id: 'a'),
          _cred(id: 'b'),
        ],
      );
      final container = _container(api);
      addTearDown(container.dispose);

      final sub = container.listen(
        webauthnCredentialsViewModelProvider(_testUserId),
        (_, _) {},
      );
      addTearDown(sub.close);
      await _pumpMicrotasks();

      final state = container.read(
        webauthnCredentialsViewModelProvider(_testUserId),
      );
      expect(state.isLoading, isFalse);
      expect(state.error, isNull);
      expect(state.credentials.map((c) => c.id), ['a', 'b']);
    });

    test('load sets error on failure', () async {
      final api = _FakeUsersApi(
        listError: DioException(requestOptions: RequestOptions()),
      );
      final container = _container(api);
      addTearDown(container.dispose);

      final sub = container.listen(
        webauthnCredentialsViewModelProvider(_testUserId),
        (_, _) {},
      );
      addTearDown(sub.close);
      await _pumpMicrotasks();

      final state = container.read(
        webauthnCredentialsViewModelProvider(_testUserId),
      );
      expect(state.isLoading, isFalse);
      expect(state.error, isNotNull);
      expect(state.credentials, isEmpty);
    });

    test('setCredentials replaces the list and clears loading', () async {
      final api = _FakeUsersApi(credentials: [_cred(id: 'a')]);
      final container = _container(api);
      addTearDown(container.dispose);

      final sub = container.listen(
        webauthnCredentialsViewModelProvider(_testUserId),
        (_, _) {},
      );
      addTearDown(sub.close);
      await _pumpMicrotasks();

      container
          .read(webauthnCredentialsViewModelProvider(_testUserId).notifier)
          .setCredentials([_cred(id: 'x'), _cred(id: 'y')]);

      final state = container.read(
        webauthnCredentialsViewModelProvider(_testUserId),
      );
      expect(state.credentials.map((c) => c.id), ['x', 'y']);
      expect(state.isLoading, isFalse);
      expect(state.error, isNull);
    });

    test('setCredentials wins over a slower in-flight load', () async {
      final completer = Completer<List<WebAuthnCredentialResponse>>();
      final api = _FakeUsersApi(onList: () => completer.future);
      final container = _container(api);
      addTearDown(container.dispose);

      final sub = container.listen(
        webauthnCredentialsViewModelProvider(_testUserId),
        (_, _) {},
      );
      addTearDown(sub.close);
      await Future<void>.delayed(Duration.zero);

      container
          .read(webauthnCredentialsViewModelProvider(_testUserId).notifier)
          .setCredentials([_cred(id: 'gateway')]);

      completer.complete([_cred(id: 'stale')]);
      await _pumpMicrotasks();

      final state = container.read(
        webauthnCredentialsViewModelProvider(_testUserId),
      );
      expect(state.credentials.map((c) => c.id), ['gateway']);
      expect(state.isLoading, isFalse);
    });
  });
}
