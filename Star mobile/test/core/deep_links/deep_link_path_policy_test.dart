import 'package:star_app/core/deep_links/deep_link_path_policy.dart';
import 'package:test/test.dart';

void main() {
  group('isAllowedDeepLinkPath', () {
    test('allows channel, invite, gift, user, and settings paths', () {
      const allowedPaths = [
        '/channels/@me',
        '/channels/123456789012345678/987654321098765432',
        '/invite/abc',
        '/gift/xyz',
        '/users/123456789012345678',
        '/settings/user',
        '/settings/user?tab=appearance',
        '/notifications',
        '/you',
      ];
      for (final String path in allowedPaths) {
        expect(
          isAllowedDeepLinkPath(Uri.parse('https://web.star.invalid$path')),
          isTrue,
          reason: path,
        );
      }
    });

    test('ignores root, auth, admin, and infra paths', () {
      for (final String path in _ignoredDeepLinkPaths) {
        expect(
          isAllowedDeepLinkPath(Uri.parse('https://web.star.invalid$path')),
          isFalse,
          reason: path,
        );
      }
    });

    test('rejects paths with blocklisted characters', () {
      expect(
        isAllowedDeepLinkPath(
          Uri.parse("https://web.star.invalid/channels/'evil"),
        ),
        isFalse,
      );
    });

    test('allows star:// app protocol URLs', () {
      const allowedStarUrls = [
        'star://channels/@me',
        'star://channels/123456789012345678/987654321098765432',
        'star://invite/abc',
        'star://gift/xyz',
        'star://users/123456789012345678',
        'star://settings/user',
        'star://settings/user?tab=appearance',
        'star://notifications',
        'star://you',
        'star:/channels/@me',
      ];
      for (final String url in allowedStarUrls) {
        expect(isAllowedDeepLinkPath(Uri.parse(url)), isTrue, reason: url);
      }
    });

    test('ignores star:// auth and infra paths', () {
      const ignoredStarUrls = [
        'star://auth/sso/callback?code=1&state=2',
        'star://login',
        'star://',
      ];
      for (final String url in ignoredStarUrls) {
        expect(isAllowedDeepLinkPath(Uri.parse(url)), isFalse, reason: url);
      }
    });
  });

  group('normalizeAppProtocolDeepLinkUri', () {
    test('maps host-style star URLs to path form', () {
      expect(
        normalizeAppProtocolDeepLinkUri(
          Uri.parse('star://channels/@me/123'),
        ).path,
        '/channels/@me/123',
      );
      expect(
        normalizeAppProtocolDeepLinkUri(Uri.parse('star://invite/abc')).path,
        '/invite/abc',
      );
      expect(
        normalizeAppProtocolDeepLinkUri(
          Uri.parse('star://settings/user?tab=appearance'),
        ),
        Uri(path: '/settings/user', queryParameters: {'tab': 'appearance'}),
      );
    });

    test('leaves https URLs unchanged', () {
      final Uri uri = Uri.parse('https://web.star.invalid/channels/@me');
      expect(normalizeAppProtocolDeepLinkUri(uri), uri);
    });
  });

  group('normalizeInviteDeepLinkUri', () {
    test('maps star.gg short links to invite paths', () {
      expect(
        normalizeInviteDeepLinkUri(Uri.parse('https://star.gg/abcd')).path,
        '/invite/abcd',
      );
      expect(
        normalizeInviteDeepLinkUri(
          Uri.parse('https://star.gg/invite/abcd'),
        ).path,
        '/invite/abcd',
      );
      expect(
        normalizeIncomingDeepLinkUri(
          Uri.parse('https://web.star.invalid/invite/abcd'),
        ).path,
        '/invite/abcd',
      );
    });

    test('allows star.gg short links through isAllowedDeepLinkPath', () {
      expect(
        isAllowedDeepLinkPath(Uri.parse('https://star.gg/abcd')),
        isTrue,
      );
    });
  });

  group('isOfficialLinkForOtherInstance', () {
    test('sends official links to the browser on a self-hosted instance', () {
      for (final String url in <String>[
        'https://star.invalid/invite/abcd',
        'https://star.invalid/channels/@me',
        'https://canary.star.invalid/gift/xyz',
        'https://star.gg/abcd',
      ]) {
        expect(
          isOfficialLinkForOtherInstance(
            Uri.parse(url),
            instanceWebAppBase: 'https://chat.example.org',
          ),
          isTrue,
          reason: url,
        );
      }
    });

    test('routes official links in the app on an official instance', () {
      for (final String base in <String>[
        'https://star.invalid/app',
        'https://web.star.invalid',
        'https://web.canary.star.invalid',
      ]) {
        expect(
          isOfficialLinkForOtherInstance(
            Uri.parse('https://star.invalid/invite/abcd'),
            instanceWebAppBase: base,
          ),
          isFalse,
          reason: base,
        );
      }
    });

    test('ignores own instance links and app protocol links', () {
      for (final String url in <String>[
        'https://chat.example.org/invite/abcd',
        'star://invite/abcd',
        '/channels/@me',
      ]) {
        expect(
          isOfficialLinkForOtherInstance(
            Uri.parse(url),
            instanceWebAppBase: 'https://chat.example.org',
          ),
          isFalse,
          reason: url,
        );
      }
    });
  });

  group('normalizeDeepLinkPath', () {
    test('trims trailing slashes and preserves root', () {
      expect(normalizeDeepLinkPath('/channels/@me/'), '/channels/@me');
      expect(normalizeDeepLinkPath('/'), '/');
      expect(normalizeDeepLinkPath(''), '/');
    });
  });

  group('isStarOAuthDeepLinkUri', () {
    test('matches oauth authorize paths on official Star web hosts', () {
      const oauthUrls = <String>[
        'https://web.star.invalid/oauth2/authorize?client_id=abc',
        'https://star.invalid/oauth2/authorize?client_id=abc',
        'https://web.canary.star.invalid/oauth2/authorize',
        'https://web.canary.star.invalid/oauth2/authorize/consent',
      ];
      for (final String url in oauthUrls) {
        expect(isStarOAuthDeepLinkUri(Uri.parse(url)), isTrue, reason: url);
      }
    });

    test('does not match star:// oauth URLs', () {
      expect(
        isStarOAuthDeepLinkUri(
          Uri.parse('star://oauth2/authorize?client_id=abc'),
        ),
        isFalse,
      );
    });

    test('matches self-hosted instance web app host', () {
      expect(
        isStarOAuthDeepLinkUri(
          Uri.parse('https://chat.example.com/oauth2/authorize'),
          instanceWebAppBase: 'https://chat.example.com',
        ),
        isTrue,
      );
    });

    test('does not match oauth paths on unrelated hosts', () {
      expect(
        isStarOAuthDeepLinkUri(
          Uri.parse('https://evil.com/oauth2/authorize'),
        ),
        isFalse,
      );
    });

    test('does not match non-oauth paths on Star hosts', () {
      expect(
        isStarOAuthDeepLinkUri(
          Uri.parse('https://web.star.invalid/channels/@me'),
        ),
        isFalse,
      );
    });
  });
}

const List<String> _ignoredDeepLinkPaths = [
  '/',
  '/authorize-ip',
  '/login',
  '/register',
  '/forgot',
  '/verify',
  '/wasntme',
  '/pending',
  '/oauth2/authorize',
  '/auth/sso/callback',
  '/report',
  '/admin',
  '/premium-callback',
  '/connection-callback',
  '/theme-studio',
  '/theme/my-theme',
  '/bookmarks',
  '/mentions',
  '/settings/guild/123',
  '/.well-known/star',
  '/_health',
];
