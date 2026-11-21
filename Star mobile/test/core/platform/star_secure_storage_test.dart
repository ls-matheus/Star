import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:star_app/core/platform/star_secure_storage.dart';

void main() {
  test('retries transient keystore failures then succeeds', () async {
    var attempts = 0;
    final String? value = await runStarSecureStorage<String?>(() async {
      attempts++;
      if (attempts < 3) {
        throw PlatformException(
          code: 'Exception encountered',
          message: 'Failed to generate key pair.',
        );
      }
      return 'ok';
    });

    expect(value, 'ok');
    expect(attempts, 3);
  });

  test('does not retry unrelated platform failures', () async {
    var attempts = 0;
    await expectLater(
      runStarSecureStorage<void>(() {
        attempts++;
        throw PlatformException(code: 'not_found');
      }),
      throwsA(isA<PlatformException>()),
    );
    expect(attempts, 1);
  });
}
