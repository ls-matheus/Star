import 'package:flutter_test/flutter_test.dart';
import 'package:star_app/features/dm/domain/dm_channel_types.dart';

void main() {
  group('resolveSystemBotDisplayName', () {
    test('returns productName for the system bot user id', () {
      expect(
        resolveSystemBotDisplayName(
          userId: starBotUserId,
          fallbackName: 'Star',
          productName: 'Acme',
        ),
        'Acme',
      );
    });

    test('keeps the existing name for other users', () {
      expect(
        resolveSystemBotDisplayName(
          userId: '42',
          fallbackName: 'Ada',
          productName: 'Acme',
        ),
        'Ada',
      );
    });
  });
}
