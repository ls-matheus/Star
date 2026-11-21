import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:star_app/core/providers/database_provider.dart';
import 'package:star_app/core/router/route_state_providers.dart';
import 'package:star_app/core/theme/star_layout_theme.dart';
import 'package:star_app/core/theme/star_text_theme.dart';
import 'package:star_app/core/theme/star_theme.dart';
import 'package:star_app/core/theme/themes/dark.dart';
import 'package:star_app/features/chat/presentation/widgets/composer/composer_autocomplete_field.dart';
import 'package:star_app/features/chat/providers/channel/channel_message_permissions_provider.dart';
import 'package:star_app/features/chat/providers/pickers/emoji_picker_provider.dart';
import 'package:star_app/features/dm/domain/dm_conversation.dart';
import 'package:star_app/features/dm/providers/dm_view_model.dart';
import 'package:star_app/features/friends/domain/friend.dart';
import 'package:star_app/features/guilds/domain/guild.dart';
import 'package:star_app/features/guilds/providers/guild_list_view_model.dart';
import 'package:star_app/material_ui.dart';
import 'package:star_app/shared/utils/emoji/emoji_registry.dart';

import '../../../../../helpers/open_test_database.dart';
import '../../../../../helpers/test_l10n.dart';

const String _channelId = 'general';
const String _guildId = 'guild_1';

class _FakeGuilds extends GuildListViewModel {
  _FakeGuilds(this._guilds);

  final List<Guild> _guilds;

  @override
  GuildListViewState build() => GuildListViewState(guilds: _guilds);
}

Widget _app(Widget child) {
  final colorTheme = buildDarkColorTheme();
  return MaterialApp(
    locale: kTestLocale,
    localizationsDelegates: starLocalizationsDelegates,
    supportedLocales: StarLocalizations.supportedLocales,
    theme: buildStarTheme(
      colorTheme: colorTheme,
      textTheme: StarTextTheme.fromColors(colorTheme),
      layoutTheme: StarLayoutTheme.scaled(),
    ),
    home: Scaffold(body: child),
  );
}

void main() {
  setUpAll(() async {
    await EmojiRegistry.preload();
  });

  testWidgets(
    'custom guild emoji surface in colon autocomplete once their stream loads',
    (tester) async {
      final emojis = StreamController<List<GuildEmojiEntry>>();
      addTearDown(emojis.close);
      final db = openTestDatabase();
      final textController = TextEditingController();
      addTearDown(textController.dispose);
      final focusNode = FocusNode();
      addTearDown(focusNode.dispose);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            starDatabaseProvider.overrideWithValue(db),
            activeGuildIdProvider.overrideWith((ref) => _guildId),
            guildListViewModelProvider.overrideWith(
              () => _FakeGuilds(const <Guild>[
                Guild(id: _guildId, name: 'Guild One', ownerId: 'owner'),
              ]),
            ),
            allGuildEmojisForPickerProvider.overrideWith(
              (ref) => emojis.stream,
            ),
            channelMessagePermissionsProvider(_channelId).overrideWith(
              (ref) => Future<ChannelMessagePermissions>.value(
                ChannelMessagePermissions.all,
              ),
            ),
            dmViewModelProvider.overrideWithValue(
              const DmViewState(
                conversations: <DmConversation>[],
                friendsList: <Friend>[],
                activeTab: FriendsTab.online,
                searchQuery: '',
              ),
            ),
          ],
          child: _app(
            ComposerAutocompleteField(
              controller: textController,
              focusNode: focusNode,
              channelId: _channelId,
              child: TextField(
                controller: textController,
                focusNode: focusNode,
              ),
            ),
          ),
        ),
      );

      textController.value = const TextEditingValue(
        text: ':party',
        selection: TextSelection.collapsed(offset: 6),
      );
      await tester.pump(const Duration(milliseconds: 350));
      expect(find.text(':partyblob:'), findsNothing);

      emojis.add(<GuildEmojiEntry>[
        GuildEmojiEntry(
          id: 'e1',
          name: 'partyblob',
          animated: false,
          guildId: _guildId,
        ),
      ]);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pump(const Duration(milliseconds: 150));

      expect(find.text(':partyblob:'), findsWidgets);
    },
  );
}
