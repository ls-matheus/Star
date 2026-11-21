import 'package:star_app/features/guilds/utils/invites/invite_link_parser.dart';
import 'package:test/test.dart';

void main() {
  group('parseInviteCode', () {
    test('parses star.gg short links', () {
      expect(parseInviteCode('https://star.gg/abcd'), 'abcd');
      expect(parseInviteCode('https://star.gg/invite/abcd'), 'abcd');
      expect(parseInviteCode('https://web.star.invalid/invite/abcd'), 'abcd');
      expect(parseInviteCode('abcd'), 'abcd');
    });

    test('returns null for non-invite links', () {
      expect(
        parseInviteCode('https://web.star.invalid/channels/123/456'),
        isNull,
      );
    });
  });
}
