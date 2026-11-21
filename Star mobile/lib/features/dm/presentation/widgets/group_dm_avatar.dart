import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:star_app/core/database/star_database.dart' as db;
import 'package:star_app/core/media/star_media_url.dart';
import 'package:star_app/core/router/star_router.dart';
import 'package:star_app/features/dm/domain/dm_conversation.dart';
import 'package:star_app/features/profile/providers/user_presence_provider.dart';
import 'package:star_app/features/ui/avatar/star_avatar_cluster.dart';
import 'package:star_app/material_ui.dart';

AvatarClusterMember _clusterMember(String userId, String? avatarHash) {
  return AvatarClusterMember(
    userId: userId,
    imageUrl: StarMediaUrl.userAvatar(userId: userId, hash: avatarHash),
  );
}

List<AvatarClusterMember> groupDmStackMembers({
  required List<GroupMemberInfo> members,
  required String? currentUserId,
  required String? currentUserAvatar,
}) {
  if (members.length == 1 && currentUserId != null) {
    return <AvatarClusterMember>[
      _clusterMember(members.first.id, members.first.avatar),
      _clusterMember(currentUserId, currentUserAvatar),
    ];
  }
  return <AvatarClusterMember>[
    for (final GroupMemberInfo member in members.take(2))
      _clusterMember(member.id, member.avatar),
  ];
}

class GroupDmAvatar extends ConsumerWidget {
  const GroupDmAvatar({
    required this.iconUrl,
    required this.members,
    required this.size,
    this.isTyping = false,
    super.key,
  });

  GroupDmAvatar.conversation(
    DmConversation dm, {
    required this.size,
    this.isTyping = false,
    super.key,
  }) : iconUrl = StarMediaUrl.guildIcon(guildId: dm.id, hash: dm.icon),
       members = dm.groupMembers;

  final String? iconUrl;
  final List<GroupMemberInfo> members;
  final double size;
  final bool isTyping;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final String? currentUserId = members.length == 1
        ? ref.watch(currentUserIdProvider)
        : null;
    final String? currentUserAvatar = currentUserId == null
        ? null
        : ref.watch(
            userRowProvider(
              currentUserId,
            ).select((AsyncValue<db.User?> user) => user.value?.avatar),
          );
    return StarAvatarCluster(
      iconUrl: iconUrl,
      isTyping: isTyping,
      members: groupDmStackMembers(
        members: members,
        currentUserId: currentUserId,
        currentUserAvatar: currentUserAvatar,
      ),
      size: size,
    );
  }
}
