// Root ProviderScope built by a helper; the lint only exempts a
// ProviderScope written inline in pumpWidget.
// ignore_for_file: riverpod_lint/scoped_providers_should_specify_dependencies

import 'package:cached_network_image_ce/cached_network_image.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:star_app/core/constants/media_proxy_sizes.dart';
import 'package:star_app/core/database/star_database.dart'
    show StarDatabase;
import 'package:star_app/core/media/star_media_url.dart';
import 'package:star_app/core/providers/database_provider.dart';
import 'package:star_app/core/theme/star_layout_theme.dart';
import 'package:star_app/core/theme/star_text_theme.dart';
import 'package:star_app/core/theme/star_theme.dart';
import 'package:star_app/core/theme/themes/dark.dart';
import 'package:star_app/features/chat/domain/message.dart';
import 'package:star_app/features/chat/presentation/widgets/messages/message_item.dart';
import 'package:star_app/features/chat/presentation/widgets/messages/message_row_layout.dart';
import 'package:star_app/features/settings/providers/preferences/chat_preferences_provider.dart';
import 'package:star_app/features/settings/providers/preferences/time_format_providers.dart';
import 'package:star_app/features/ui/avatar/star_avatar.dart';
import 'package:star_app/features/ui/status_indicator/star_status_indicator.dart';
import 'package:star_app/material_ui.dart';
import 'package:star_app/shared/providers/guild_user_display_provider.dart';
import 'package:star_app/shared/providers/member_role_color.dart';
import 'package:star_app/shared/utils/guild_user_display.dart';
import 'package:star_dart/export.dart';

import '../../../../../helpers/instance_runtime_config_override.dart';
import '../../../../../helpers/message_item_test_overrides.dart';
import '../../../../../helpers/open_test_database.dart';
import '../../../../../helpers/test_l10n.dart';

const String _authorId = '123456789012345678';
const String _guildId = 'g1';
const String _globalAvatarHash = 'global_avatar_hash';

String get _defaultAvatarUrl {
  final index = BigInt.parse(_authorId) % BigInt.from(6);
  return 'https://starstatic.com/avatars/$index.png';
}

String get _globalAvatarUrl => StarMediaUrl.userAvatar(
  userId: _authorId,
  hash: _globalAvatarHash,
  size: MediaProxySizes.avatarProfile,
)!;

Message _message() => Message(
  id: 'msg-1',
  channelId: 'c1',
  authorId: _authorId,
  authorName: 'Alice',
  authorAvatar: _globalAvatarHash,
  content: 'hello',
  timestamp: DateTime.utc(2026, 1, 1, 12),
);

const MessageRenderSettings _settings = MessageRenderSettings(
  activeGuildId: _guildId,
  renderEmbeds: false,
  renderReactions: false,
  inlineAttachmentMedia: false,
  renderSpoilers: RenderSpoilers.onClick,
  revealSpoilers: false,
  chatPreferences: ChatPreferencesState(),
  messageGroupSpacing: 16,
);

const GuildUserDisplay _unsetDisplay = GuildUserDisplay(
  displayName: 'Alice',
  accountDisplayName: 'Alice',
  avatarUrl: null,
  avatarHash: _globalAvatarHash,
  avatarColor: null,
);

final GuildUserDisplay _shownDisplay = GuildUserDisplay(
  displayName: 'Alice',
  accountDisplayName: 'Alice',
  avatarUrl: _globalAvatarUrl,
  avatarHash: _globalAvatarHash,
  avatarColor: null,
);

Widget _app({
  required GuildUserDisplay authorDisplay,
  required Message message,
}) {
  final colorTheme = buildDarkColorTheme();
  return ProviderScope(
    key: ValueKey<Object>(authorDisplay.avatarUrl ?? 'unset'),
    overrides: [
      starDatabaseProvider.overrideWithValue(_database),
      instanceRuntimeConfigOverride(),
      ...messageItemTestProviderOverrides(),
      guildUserDisplayProvider((
        _authorId,
        _guildId,
      )).overrideWith((ref) => AsyncValue.data(authorDisplay)),
      guildUserDisplayFromDbProvider((
        _authorId,
        _guildId,
      )).overrideWith((ref) => AsyncValue.data(authorDisplay)),
      memberRoleColorProvider((
        _authorId,
        _guildId,
      )).overrideWith((ref) => null),
      use12HourTimeFormatProvider.overrideWithValue(false),
    ],
    child: MaterialApp(
      locale: kTestLocale,
      localizationsDelegates: starLocalizationsDelegates,
      supportedLocales: StarLocalizations.supportedLocales,
      theme: buildStarTheme(
        colorTheme: colorTheme,
        textTheme: StarTextTheme.fromColors(colorTheme),
        layoutTheme: StarLayoutTheme.scaled(),
      ),
      home: Scaffold(
        body: MessageItem(message: message, renderSettings: _settings),
      ),
    ),
  );
}

CachedNetworkImage _avatarImage(WidgetTester tester) {
  final images = tester.widgetList<CachedNetworkImage>(
    find.byType(CachedNetworkImage),
  );
  expect(
    images,
    isNotEmpty,
    reason: 'message row should render an avatar image',
  );
  return images.first;
}

late StarDatabase _database;

void main() {
  setUp(() {
    _database = openTestDatabase();
  });

  group('MessageItem author avatar', () {
    messageItemTestWidgets('never shows presence on the author avatar', (
      tester,
    ) async {
      await tester.pumpWidget(
        _app(authorDisplay: _shownDisplay, message: _message()),
      );
      await tester.pump();

      final StarAvatar avatar = tester.widget<StarAvatar>(
        find.byType(StarAvatar),
      );
      expect(avatar.showStatus, isFalse);
      expect(avatar.size, kMessageAvatarSize);
      expect(find.byType(StarStatusIndicator), findsNothing);
    });
  });

  group('MessageItem avatar AVATAR_UNSET', () {
    messageItemTestWidgets(
      'avatar-unset member message requests default avatar URL, not global',
      (tester) async {
        await tester.pumpWidget(
          _app(authorDisplay: _unsetDisplay, message: _message()),
        );
        await tester.pump();

        final image = _avatarImage(tester);
        expect(image.imageUrl, _defaultAvatarUrl);
        expect(image.imageUrl, isNot(_globalAvatarUrl));
        expect(image.imageUrl, isNot(contains('/avatars/$_authorId/')));
        expect(image.imageUrl, isNot(contains(_globalAvatarHash)));
      },
    );

    messageItemTestWidgets(
      'same author flips between global and default URLs when unset toggles',
      (tester) async {
        await tester.pumpWidget(
          _app(authorDisplay: _shownDisplay, message: _message()),
        );
        await tester.pump();
        expect(_avatarImage(tester).imageUrl, _globalAvatarUrl);

        await tester.pumpWidget(
          _app(authorDisplay: _unsetDisplay, message: _message()),
        );
        await tester.pump();
        final unsetImage = _avatarImage(tester);
        expect(unsetImage.imageUrl, _defaultAvatarUrl);
        expect(unsetImage.imageUrl, isNot(_globalAvatarUrl));

        await tester.pumpWidget(
          _app(authorDisplay: _shownDisplay, message: _message()),
        );
        await tester.pump();
        expect(_avatarImage(tester).imageUrl, _globalAvatarUrl);
      },
    );

    messageItemTestWidgets(
      'avatar identity stays stable across optimistic→delivered message id swap',
      (tester) async {
        final optimistic = _message().copyWith(id: 'optimistic-temp-id');
        final delivered = _message().copyWith(id: 'delivered-snowflake-id');

        await tester.pumpWidget(
          _app(authorDisplay: _unsetDisplay, message: optimistic),
        );
        await tester.pump();
        final before = _avatarImage(tester).imageUrl;

        await tester.pumpWidget(
          _app(authorDisplay: _unsetDisplay, message: delivered),
        );
        await tester.pump();
        final after = _avatarImage(tester).imageUrl;

        expect(before, _defaultAvatarUrl);
        expect(after, before);
      },
    );
  });
}
