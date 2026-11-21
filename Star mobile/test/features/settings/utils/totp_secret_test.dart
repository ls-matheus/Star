import 'package:flutter_test/flutter_test.dart';
import 'package:star_app/features/settings/utils/totp_secret.dart';

void main() {
  group('encodeTotpKey', () {
    test('matches web AuthMfaUtils bit packing', () {
      expect(encodeTotpKey(List<int>.filled(20, 0)), 'A' * 32);
      expect(encodeTotpKey(List<int>.filled(20, 255)), '7' * 32);
      expect(
        encodeTotpKey(<int>[
          1,
          2,
          3,
          4,
          5,
          6,
          7,
          8,
          9,
          10,
          11,
          12,
          13,
          14,
          15,
          16,
          17,
          18,
          19,
          20,
        ]),
        'AEBAGBAFAYDQQCIKBMGA2DQPCAIREEYU',
      );
    });
  });

  group('encodeTotpSecret', () {
    test('strips separators and uppercases', () {
      expect(encodeTotpSecret('ab cd_ef-gh.ij'), 'ABCDEFGHIJ');
    });
  });

  group('encodeTotpSecretAsUrl', () {
    test('matches web otpauth encoding for email accounts', () {
      expect(
        encodeTotpSecretAsUrl(
          accountName: 'alice@example.com',
          secret: 'jbswy3dpehpk3pxp',
          issuer: 'Star',
        ),
        'otpauth://totp/Star:alice%40example.com?secret=JBSWY3DPEHPK3PXP&issuer=Star',
      );
    });

    test('encodes plus signs in email the same as web', () {
      expect(
        encodeTotpSecretAsUrl(
          accountName: 'user+tag@example.com',
          secret: 'AAAA',
          issuer: 'Star',
        ),
        'otpauth://totp/Star:user%2Btag%40example.com?secret=AAAA&issuer=Star',
      );
    });

    test('encodes issuer spaces in the label and query', () {
      expect(
        encodeTotpSecretAsUrl(
          accountName: 'alice',
          secret: 'ABCDEF',
          issuer: 'My App',
        ),
        'otpauth://totp/My%20App:alice?secret=ABCDEF&issuer=My+App',
      );
    });
  });

  group('generateTotpSecret', () {
    test('returns 32 base32 characters from 20 bytes', () {
      final String secret = generateTotpSecret();
      expect(secret, hasLength(32));
      expect(secret, matches(RegExp(r'^[A-Z2-7]+$')));
    });
  });
}
