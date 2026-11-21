import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:star_app/core/api/star_client_provider.dart';
import 'package:star_app/features/auth/providers/current_auth_session_provider.dart';

void main() {
  test('token swap between accounts clears the session id hash', () {
    final ProviderContainer container = ProviderContainer();
    addTearDown(container.dispose);

    container.read(starAuthTokenProvider.notifier).setToken('token-a');
    container.read(currentAuthSessionIdHashProvider.notifier).update('hash-a');
    expect(container.read(currentAuthSessionIdHashProvider), 'hash-a');

    container.read(starAuthTokenProvider.notifier).setToken('token-b');
    expect(container.read(currentAuthSessionIdHashProvider), isNull);
  });
}
