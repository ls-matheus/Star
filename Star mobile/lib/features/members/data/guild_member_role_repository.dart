import 'package:dio/dio.dart';
import 'package:star_app/core/api/api_exception.dart';
import 'package:star_dart/export.dart';

class GuildMemberRoleRepository {
  const GuildMemberRoleRepository(this._client);

  final StarClient _client;

  Future<void> addMemberRole({
    required String guildId,
    required String userId,
    required String roleId,
  }) async {
    try {
      await _client.guilds.addGuildMemberRole(
        guildId: guildId,
        userId: userId,
        roleId: roleId,
      );
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  Future<void> removeMemberRole({
    required String guildId,
    required String userId,
    required String roleId,
  }) async {
    try {
      await _client.guilds.removeGuildMemberRole(
        guildId: guildId,
        userId: userId,
        roleId: roleId,
      );
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }
}
