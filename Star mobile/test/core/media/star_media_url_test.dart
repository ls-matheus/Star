import 'package:flutter_test/flutter_test.dart';
import 'package:star_app/core/constants/media_proxy_sizes.dart';
import 'package:star_app/core/media/star_media_url.dart';

void main() {
  group('StarMediaUrl.userAvatar', () {
    test('returns null when hash is null or empty', () {
      expect(StarMediaUrl.userAvatar(userId: '1', hash: null), isNull);
      expect(StarMediaUrl.userAvatar(userId: '1', hash: ''), isNull);
    });

    test('returns webp with size for static hash when animated is false', () {
      final String? actual = StarMediaUrl.userAvatar(
        userId: '1',
        hash: 'user_avatar',
      );
      expect(actual, contains('/avatars/1/user_avatar.webp'));
      expect(actual, contains('size=${MediaProxySizes.avatarDefault}'));
      expect(actual, isNot(contains('animated=true')));
    });

    test('returns gif when animated is true and hash is animated', () {
      final String? actual = StarMediaUrl.userAvatar(
        userId: '1',
        hash: 'a_user_avatar',
        animated: true,
      );
      expect(
        actual,
        contains(
          '/avatars/1/a_user_avatar.gif?animated=true&size='
          '${MediaProxySizes.avatarDefault}',
        ),
      );
    });

    test('returns webp when animated is true but hash is static', () {
      final String? actual = StarMediaUrl.userAvatar(
        userId: '1',
        hash: 'user_avatar',
        animated: true,
      );
      expect(actual, contains('/avatars/1/user_avatar.webp'));
      expect(actual, isNot(contains('.gif')));
    });

    test('returns webp for animated hash when animated is false', () {
      final String? actual = StarMediaUrl.userAvatar(
        userId: '1',
        hash: 'a_user_avatar',
      );
      expect(actual, contains('/avatars/1/user_avatar.webp'));
      expect(actual, isNot(contains('animated=true')));
    });
  });

  group('StarMediaUrl.userBanner', () {
    test('returns null when hash is null', () {
      expect(StarMediaUrl.userBanner(userId: '1', hash: null), isNull);
    });

    test('returns animated gif when hash is animated and animated is true', () {
      final String? actual = StarMediaUrl.userBanner(
        userId: '1',
        hash: 'a_banner',
        animated: true,
      );
      expect(actual, contains('/banners/1/a_banner.gif?animated=true&size='));
    });

    test('returns webp for static hash', () {
      final String? actual = StarMediaUrl.userBanner(
        userId: '1',
        hash: 'user_banner',
      );
      expect(actual, contains('/banners/1/user_banner.webp'));
    });
  });

  group('StarMediaUrl.guildIcon', () {
    test('returns null when hash is null', () {
      expect(StarMediaUrl.guildIcon(guildId: '10', hash: null), isNull);
    });

    test('returns png for static hash when animated is false', () {
      final String? actual = StarMediaUrl.guildIcon(
        guildId: '10',
        hash: 'icon_hash',
      );
      expect(actual, contains('/icons/10/icon_hash.png'));
    });

    test(
      'returns webp with animated=false for animated hash when animated is false',
      () {
        final String? actual = StarMediaUrl.guildIcon(
          guildId: '10',
          hash: 'a_icon',
        );
        expect(actual, contains('/icons/10/a_icon.webp?animated=false'));
      },
    );

    test('returns gif when animated is true and hash is animated', () {
      final String? actual = StarMediaUrl.guildIcon(
        guildId: '10',
        hash: 'a_icon',
        animated: true,
      );
      expect(actual, contains('/icons/10/a_icon.gif?animated=true'));
    });

    test('includes the default size for a static hash', () {
      final String? actual = StarMediaUrl.guildIcon(
        guildId: '10',
        hash: 'icon_hash',
      );
      expect(actual, contains('size=${MediaProxySizes.iconDefault}'));
    });

    test('includes a custom size for an animated hash', () {
      final String? actual = StarMediaUrl.guildIcon(
        guildId: '10',
        hash: 'a_icon',
        animated: true,
        size: 256,
      );
      expect(actual, contains('/icons/10/a_icon.gif'));
      expect(actual, contains('size=256'));
    });
  });

  group('StarMediaUrl.guildBanner', () {
    test('returns png with size for static hash', () {
      final String? actual = StarMediaUrl.guildBanner(
        guildId: '10',
        hash: 'banner',
      );
      expect(
        actual,
        contains(
          '/banners/10/banner.png?size=${MediaProxySizes.guildBannerDefault}',
        ),
      );
    });

    test('returns gif when animated is true and hash is animated', () {
      final String? actual = StarMediaUrl.guildBanner(
        guildId: '10',
        hash: 'a_banner',
        animated: true,
      );
      expect(actual, contains('/banners/10/a_banner.gif?animated=true&size='));
    });
  });

  group('StarMediaUrl.guildMemberMedia', () {
    test('returns webp for static guild member avatar', () {
      final String actual = StarMediaUrl.guildMemberMedia(
        guildId: '10',
        userId: '1',
        type: GuildMemberMediaType.avatar,
        hash: 'guild_avatar',
      );
      expect(actual, contains('/guilds/10/users/1/avatars/guild_avatar.webp'));
    });

    test(
      'returns gif for animated guild member avatar when animated is true',
      () {
        final String actual = StarMediaUrl.guildMemberMedia(
          guildId: '10',
          userId: '1',
          type: GuildMemberMediaType.avatar,
          hash: 'a_guild_avatar',
          animated: true,
        );
        expect(
          actual,
          contains(
            '/guilds/10/users/1/avatars/a_guild_avatar.gif?animated=true&size=',
          ),
        );
      },
    );
  });

  group('StarMediaUrl.customEmoji', () {
    test('includes lossless quality by default', () {
      expect(
        StarMediaUrl.customEmoji(id: '123'),
        'https://starusercontent.com/emojis/123.webp?quality=lossless',
      );
    });

    test('keeps animated requests lossless (#776)', () {
      final String actual = StarMediaUrl.customEmoji(
        id: '123',
        animated: true,
        size: 48,
      );
      expect(
        actual,
        'https://starusercontent.com/emojis/123.webp'
        '?animated=true&quality=lossless&size=48',
      );
    });
  });

  group('StarMediaUrl.sticker', () {
    test('clamps size to 320 or 160', () {
      expect(StarMediaUrl.sticker(id: '1'), contains('size=320'));
      expect(StarMediaUrl.sticker(id: '1', size: 100), contains('size=160'));
    });

    test('includes animated query param when requested', () {
      expect(
        StarMediaUrl.sticker(id: '1', animated: true),
        contains('animated=true'),
      );
    });
  });

  group('StarMediaUrl.guildEmbedSplash', () {
    test('returns null when hash is null', () {
      expect(
        StarMediaUrl.guildEmbedSplash(guildId: '10', hash: null),
        isNull,
      );
    });

    test('returns webp with size', () {
      final String? actual = StarMediaUrl.guildEmbedSplash(
        guildId: '10',
        hash: 'splash',
      );
      expect(
        actual,
        contains(
          '/embed-splashes/10/splash.webp?size='
          '${MediaProxySizes.guildEmbedSplashDefault}',
        ),
      );
    });
  });

  group('StarMediaUrl.roleIcon', () {
    test('returns data uri unchanged', () {
      const String dataUri = 'data:image/png;base64,abc';
      expect(
        StarMediaUrl.roleIcon(roleId: '1', hash: dataUri, cssSize: 20),
        dataUri,
      );
    });

    test('returns webp role icon url', () {
      final String? actual = StarMediaUrl.roleIcon(
        roleId: '99',
        hash: 'abc123',
        cssSize: 20,
      );
      expect(actual, contains('/role-icons/99/abc123.webp'));
      expect(actual, contains('size='));
    });
  });
}
