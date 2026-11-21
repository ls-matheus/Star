import 'package:star_app/core/database/star_database.dart' as db;
import 'package:star_app/features/channels/domain/channel.dart';
import 'package:star_app/features/dm/domain/dm_conversation.dart';
import 'package:star_app/features/guilds/domain/guild.dart';
import 'package:star_app/l10n/generated/star_localizations.dart';

class ResolvedFavoriteEntry {
  const ResolvedFavoriteEntry({
    required this.favorite,
    required this.channel,
    required this.dm,
    required this.guildId,
    required this.guild,
  });

  final db.FavoriteChannel favorite;
  final Channel? channel;
  final DmConversation? dm;
  final String? guildId;
  final Guild? guild;

  String get channelId => favorite.channelId;

  String displayName(StarLocalizations l10n) =>
      favorite.nickname ??
      channel?.name ??
      (dm == null ? null : dmConversationDisplayName(l10n, dm!)) ??
      favorite.channelId;
}

class FavoriteChannelGroup {
  const FavoriteChannelGroup({
    required this.categoryId,
    required this.title,
    required this.entries,
  });

  final String? categoryId;
  final String title;
  final List<ResolvedFavoriteEntry> entries;
}
