import 'package:dio/dio.dart';
import 'package:star_app/core/api/star_client_provider.dart';
import 'package:star_app/core/providers/keep_alive_for.dart';
import 'package:star_app/features/guilds/utils/invites/invite_code.dart';
import 'package:star_dart/export.dart';
import 'package:riverpod/misc.dart' show KeepAliveLink;
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'invite_embed_provider.g.dart';

const Duration kInviteEmbedIdleRetention = Duration(minutes: 10);

sealed class InviteEmbedState {}

class InviteEmbedLoading extends InviteEmbedState {}

class InviteEmbedNotFound extends InviteEmbedState {}

class InviteEmbedGuild extends InviteEmbedState {
  InviteEmbedGuild(this.invite);
  final InviteResponseSchemaGuildInviteResponse invite;
}

class InviteEmbedGroupDm extends InviteEmbedState {
  InviteEmbedGroupDm(this.invite);
  final InviteResponseSchemaGroupDmInviteResponse invite;
}

@riverpod
Future<InviteEmbedState> inviteEmbed(Ref ref, String code) async {
  final KeepAliveLink keepAlive = keepAliveFor(ref, kInviteEmbedIdleRetention);
  final client = ref.read(starClientProvider);
  try {
    final InviteResponseSchema schema = await client.invites.getInvite(
      inviteCode: code,
    );
    if (inviteResponseIsGuild(schema)) {
      return InviteEmbedGuild(schema.toGuildInviteResponse());
    }
    return InviteEmbedGroupDm(schema.toGroupDmInviteResponse());
  } on DioException catch (e) {
    if (e.response?.statusCode == 404) {
      return InviteEmbedNotFound();
    }
    keepAlive.close();
    rethrow;
  } on Object {
    keepAlive.close();
    rethrow;
  }
}
