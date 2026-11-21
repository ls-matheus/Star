// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'operator_pass_labs_join_response_status_status.dart';
import 'snowflake_string_type.dart';

part 'operator_pass_labs_join_response.g.dart';

@JsonSerializable()
class OperatorPassLabsJoinResponse {
  const OperatorPassLabsJoinResponse({
    required this.status,
    required this.guildId,
    required this.operatorsChannelId,
  });

  factory OperatorPassLabsJoinResponse.fromJson(Map<String, Object?> json) =>
      _$OperatorPassLabsJoinResponseFromJson(json);

  /// joined: the account is in Star Labs with the Operator role. left: the account left Star Labs or was removed from it before, so it is not added again and can join with the invite. banned: the account is banned from Star Labs. unavailable: the account cannot be added right now
  @JsonKey(defaultValue: OperatorPassLabsJoinResponseStatusStatus.$unknown)
  final OperatorPassLabsJoinResponseStatusStatus status;

  /// ID of the Star Labs community, null when it is not set up
  @JsonKey(includeIfNull: true, name: 'guild_id')
  final SnowflakeStringType? guildId;

  /// ID of the #operators channel in Star Labs, null when it is not set up
  @JsonKey(includeIfNull: true, name: 'operators_channel_id')
  final SnowflakeStringType? operatorsChannelId;

  Map<String, Object?> toJson() => _$OperatorPassLabsJoinResponseToJson(this);
}
