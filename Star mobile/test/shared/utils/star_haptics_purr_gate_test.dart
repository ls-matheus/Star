import 'package:flutter_test/flutter_test.dart';
import 'package:star_app/shared/utils/star_haptics.dart';

void main() {
  group('StarHapticPurrGate', () {
    late DateTime now;
    late StarHapticPurrGate gate;

    setUp(() {
      now = DateTime(2026);
      gate = StarHapticPurrGate(now: () => now);
    });

    test('allows the first purr', () {
      expect(gate.tryAcquire(), isTrue);
    });

    test('rejects purrs inside the min interval', () {
      expect(gate.tryAcquire(), isTrue);
      now = now.add(const Duration(seconds: 7));
      expect(gate.tryAcquire(), isFalse);
    });

    test('allows another purr after the min interval', () {
      expect(gate.tryAcquire(), isTrue);
      now = now.add(const Duration(seconds: 8));
      expect(gate.tryAcquire(), isTrue);
    });

    test('caps purrs inside the rolling window', () {
      expect(gate.tryAcquire(), isTrue);
      now = now.add(const Duration(seconds: 8));
      expect(gate.tryAcquire(), isTrue);
      now = now.add(const Duration(seconds: 8));
      expect(gate.tryAcquire(), isTrue);
      now = now.add(const Duration(seconds: 8));
      expect(gate.tryAcquire(), isFalse);
    });

    test('allows another purr once the oldest play leaves the window', () {
      expect(gate.tryAcquire(), isTrue);
      now = now.add(const Duration(seconds: 8));
      expect(gate.tryAcquire(), isTrue);
      now = now.add(const Duration(seconds: 8));
      expect(gate.tryAcquire(), isTrue);

      now = now.add(const Duration(seconds: 29));
      expect(gate.tryAcquire(), isTrue);
    });
  });
}
