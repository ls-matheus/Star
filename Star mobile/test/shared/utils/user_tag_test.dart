import 'package:flutter_test/flutter_test.dart';
import 'package:star_app/shared/utils/star_tag_parser.dart';
import 'package:star_app/shared/utils/user_tag.dart';

void main() {
  group('formatUserTag', () {
    test('keeps the tag when usernames are not unique', () {
      expect(
        formatUserTag('alice', '0000', uniqueUsernames: false),
        'alice#0000',
      );
      expect(
        formatUserTag('alice', '1234', uniqueUsernames: false),
        'alice#1234',
      );
    });

    test('hides the zero tag when usernames are unique', () {
      expect(formatUserTag('alice', '0000', uniqueUsernames: true), 'alice');
      expect(formatUserTag('alice', '0', uniqueUsernames: true), 'alice');
    });

    test('keeps a real tag and bot tags when usernames are unique', () {
      expect(
        formatUserTag('alice', '0042', uniqueUsernames: true),
        'alice#0042',
      );
      expect(
        formatUserTag('helper', '0000', uniqueUsernames: true, bot: true),
        'helper#0000',
      );
    });
  });

  group('parseStarTagInput', () {
    test('a bare username targets the zero tag', () {
      final parsed = parseStarTagInput('alice');
      expect(parsed.username, 'alice');
      expect(parsed.discriminator, '0000');
    });

    test('a short zero tag is padded only for unique usernames', () {
      expect(
        parseStarTagInput('alice#0', uniqueUsernames: true).discriminator,
        '0000',
      );
      expect(parseStarTagInput('alice#0').discriminator, '0');
    });
  });
}
