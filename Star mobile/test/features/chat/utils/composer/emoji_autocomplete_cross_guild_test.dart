import 'package:drift/drift.dart' show Value;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:star_app/core/database/star_database.dart';
import 'package:star_app/core/providers/database_provider.dart';
import 'package:star_app/features/chat/providers/pickers/emoji_picker_provider.dart';
import 'package:star_app/features/chat/utils/composer/emoji_autocomplete_search.dart';
import 'package:star_app/shared/utils/emoji/emoji_registry.dart';

import '../../../../helpers/open_test_database.dart';

void main() {
  test(
    'allGuildEmojisForPickerProvider yields emoji from every guild',
    () async {
      final StarDatabase db = openTestDatabase();
      await db.guildEmojiDao.replaceForGuild('g_active', <GuildEmojisCompanion>[
        GuildEmojisCompanion.insert(
          id: 'e1',
          guildId: 'g_active',
          name: 'monkey',
          animated: const Value(false),
        ),
      ]);
      await db.guildEmojiDao.replaceForGuild('g_other', <GuildEmojisCompanion>[
        GuildEmojisCompanion.insert(
          id: 'e2',
          guildId: 'g_other',
          name: 'agooglemonkey',
          animated: const Value(false),
        ),
      ]);

      final ProviderContainer container = ProviderContainer(
        overrides: [starDatabaseProvider.overrideWithValue(db)],
      );
      addTearDown(container.dispose);
      container.listen(allGuildEmojisForPickerProvider, (_, _) {});
      final List<GuildEmojiEntry> emojis = await container.read(
        allGuildEmojisForPickerProvider.future,
      );
      expect(
        emojis.map((GuildEmojiEntry e) => e.guildId).toSet(),
        containsAll(<String>['g_active', 'g_other']),
      );

      final List<EmojiAutocompleteResult> results = searchEmojiAutocomplete(
        matchedText: 'monkey',
        unicode: const <EmojiEntry>[],
        custom: emojis,
        score: (String _) => 0,
        limit: 10,
      );
      final Set<String> matchedNames = results
          .whereType<CustomEmojiResult>()
          .map((CustomEmojiResult r) => r.entry.name)
          .toSet();
      expect(matchedNames, containsAll(<String>['monkey', 'agooglemonkey']));
    },
  );
}
