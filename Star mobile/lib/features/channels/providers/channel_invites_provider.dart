import 'package:star_app/core/api/star_client_provider.dart';
import 'package:star_app/features/settings/domain/guild/guild_invite_entry.dart';
import 'package:star_app/features/settings/domain/guild/guild_invites_state.dart';
import 'package:star_dart/export.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'channel_invites_provider.g.dart';

@riverpod
class ChannelInvites extends _$ChannelInvites {
  @override
  Future<GuildInvitesState> build(String channelId) {
    return _loadState();
  }

  Future<void> reload() async {
    state = const AsyncLoading<GuildInvitesState>();
    state = AsyncData<GuildInvitesState>(await _loadState());
  }

  Future<void> revokeInvite(String code) async {
    final GuildInvitesState? current = state.value;
    if (current == null || current.revokingCode != null) {
      return;
    }
    state = AsyncData<GuildInvitesState>(current.copyWith(revokingCode: code));
    try {
      await ref
          .read(starClientProvider)
          .invites
          .deleteInvite(inviteCode: code);
      final List<GuildInviteEntry> updatedInvites = current.invites
          .where((GuildInviteEntry entry) => entry.code != code)
          .toList();
      state = AsyncData<GuildInvitesState>(
        current.copyWith(invites: updatedInvites, clearRevokingCode: true),
      );
    } on Object {
      state = AsyncData<GuildInvitesState>(
        current.copyWith(clearRevokingCode: true),
      );
      rethrow;
    }
  }

  Future<GuildInvitesState> _loadState() async {
    try {
      final List<InviteMetadataResponseSchema> response = await ref
          .read(starClientProvider)
          .invites
          .listChannelInvites(channelId: channelId);
      final List<GuildInviteEntry> invites = response
          .map(GuildInviteEntry.fromResponse)
          .toList();
      return GuildInvitesState(
        loadStatus: GuildInvitesLoadStatus.success,
        invites: invites,
      );
    } on Object {
      return const GuildInvitesState(
        loadStatus: GuildInvitesLoadStatus.error,
        invites: <GuildInviteEntry>[],
      );
    }
  }
}
