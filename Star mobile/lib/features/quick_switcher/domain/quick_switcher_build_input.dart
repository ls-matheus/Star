import 'package:star_app/features/channels/domain/channel.dart';
import 'package:star_app/features/dm/domain/dm_conversation.dart';
import 'package:star_app/features/friends/domain/friend.dart';
import 'package:star_app/features/guilds/domain/guild.dart';
import 'package:star_app/features/members/domain/member.dart';
import 'package:star_app/l10n/generated/star_localizations.dart';

class QuickSwitcherBuildInput {
  const QuickSwitcherBuildInput({
    required this.l10n,
    required this.currentUserId,
    required this.conversations,
    required this.friends,
    required this.guildChannels,
    required this.guilds,
    required this.guildMembers,
    required this.hasFavorites,
    this.directMessagesDisabled = false,
    this.uniqueUsernames = false,
  });

  final StarLocalizations l10n;
  final String? currentUserId;
  final List<DmConversation> conversations;
  final List<Friend> friends;
  final List<Channel> guildChannels;
  final List<Guild> guilds;
  final List<Member> guildMembers;
  final bool hasFavorites;
  final bool directMessagesDisabled;
  final bool uniqueUsernames;
}
