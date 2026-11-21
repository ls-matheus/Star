import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show StreamProviderFamily;
import 'package:star_app/core/providers/database_provider.dart';
import 'package:star_app/features/channels/data/unread_settings_resolver.dart';
import 'package:star_app/features/channels/domain/channel.dart';
import 'package:star_app/features/forum/domain/forum_channel.dart';
import 'package:star_app/features/forum/presentation/widgets/forum_sort_view_panel.dart';
import 'package:star_app/features/guilds/data/guild_user_settings_repository.dart';
import 'package:star_app/features/ui/bottom_sheet/star_bottom_sheet.dart';
import 'package:star_app/features/ui/switch_group/star_switch_group.dart';
import 'package:star_app/l10n/generated/star_localizations.dart';
import 'package:star_app/material_ui.dart';

final StreamProviderFamily<int?, ({String guildId, String forumId})>
forumOverrideFlagsProvider = StreamProvider.autoDispose
    .family<int?, ({String guildId, String forumId})>(
      (Ref ref, ({String guildId, String forumId}) key) => ref
          .watch(starDatabaseProvider)
          .userGuildSettingsDao
          .watchByGuildId(key.guildId)
          .map(
            (row) => row == null
                ? null
                : decodeUserGuildSettings(
                    row.data,
                  )?.channelOverrides?[key.forumId]?.flags,
          )
          .distinct(),
    );

Future<void> showForumViewOptionsSheet(
  BuildContext context, {
  required Channel forum,
}) => StarBottomSheet.show<void>(
  context,
  title: StarLocalizations.of(context).forumViewOptions,
  variant: StarBottomSheetVariant.menu,
  builder: (BuildContext sheetContext, VoidCallback close) =>
      _ForumViewOptions(forum: forum),
);

class _ForumViewOptions extends ConsumerWidget {
  const _ForumViewOptions({required this.forum});

  final Channel forum;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final StarLocalizations l10n = StarLocalizations.of(context);
    final int? flags = ref
        .watch(
          forumOverrideFlagsProvider((
            guildId: forum.guildId,
            forumId: forum.id,
          )),
        )
        .value;
    return StarBottomSheetContent(
      child: StarBottomSheetGroupColumn(
        children: <Widget>[
          ForumSortViewPanel(forum: forum, forSheet: true),
          StarSwitchGroup(
            children: <Widget>[
              StarSwitchGroupItem(
                value: forumNewPostsUnreadEnabled(flags),
                label: l10n.forumNewPostsUnread,
                description: l10n.forumNewPostsUnreadDescription,
                onChanged: (bool enabled) => unawaited(
                  ref
                      .read(guildUserSettingsRepositoryProvider)
                      .updateChannelOverride(
                        guildId: forum.guildId,
                        channelId: forum.id,
                        flags: withForumNewPostsUnread(flags, enabled: enabled),
                      ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
