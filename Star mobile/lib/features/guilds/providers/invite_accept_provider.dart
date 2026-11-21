import 'package:dio/dio.dart';
import 'package:star_app/core/api/star_client_provider.dart';
import 'package:star_app/features/guilds/utils/invites/invite_code.dart';
import 'package:star_dart/export.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'invite_accept_provider.g.dart';

sealed class InviteAcceptState {}

class InviteAcceptLoading extends InviteAcceptState {}

class InviteAcceptNotFound extends InviteAcceptState {}

class InviteAcceptGuild extends InviteAcceptState {
  InviteAcceptGuild(this.invite);
  final InviteResponseSchemaGuildInviteResponse invite;
}

class InviteAcceptGroupDm extends InviteAcceptState {
  InviteAcceptGroupDm(this.invite);
  final InviteResponseSchemaGroupDmInviteResponse invite;
}

@riverpod
Future<InviteAcceptState> inviteAccept(Ref ref, String code) async {
  final client = ref.watch(starClientProvider);
  try {
    final InviteResponseSchema schema = await client.invites.getInvite(
      inviteCode: code,
    );
    if (inviteResponseIsGuild(schema)) {
      return InviteAcceptGuild(schema.toGuildInviteResponse());
    }
    return InviteAcceptGroupDm(schema.toGroupDmInviteResponse());
  } on DioException catch (e) {
    if (e.response?.statusCode == 404) {
      return InviteAcceptNotFound();
    }
    rethrow;
  }
}
