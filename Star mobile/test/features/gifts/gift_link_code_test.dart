import 'package:flutter_test/flutter_test.dart';
import 'package:star_app/features/gifts/utils/gift_code_utils.dart';

void main() {
  test('an official gift link is recognised so it opens in the app', () {
    expect(parseGiftLinkCode('https://star.gift/AbC-123'), 'AbC-123');
    expect(parseGiftLinkCode('https://star.invalid/gift/AbC-123/'), 'AbC-123');
  });

  test('a link that only contains a gift path is not treated as a gift', () {
    expect(parseGiftLinkCode('https://star.invalid/gift/AbC-123/extra'), isNull);
    expect(parseGiftLinkCode('https://example.com/gift/AbC-123'), isNull);
  });
}
