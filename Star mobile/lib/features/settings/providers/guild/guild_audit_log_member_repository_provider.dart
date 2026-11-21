import 'package:star_app/core/api/star_client_provider.dart';
import 'package:star_app/core/providers/database_provider.dart';
import 'package:star_app/core/providers/gateway/gateway_connection_provider.dart';
import 'package:star_app/features/members/providers/guild_member_chunk_waiter.dart';
import 'package:star_app/features/settings/data/guild_audit_log_member_repository.dart';
import 'package:star_dart/gateway.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'guild_audit_log_member_repository_provider.g.dart';

GatewayConnection? _readConnectedGateway(Ref ref) {
  try {
    final GatewayConnection gateway = ref.read(gatewayConnectionProvider);
    if (gateway.state == GatewayState.connected) {
      return gateway;
    }
  } on Object {
    // Gateway is unavailable while logged out or reconnecting.
  }
  return null;
}

@Riverpod(keepAlive: true)
GuildAuditLogMemberRepository guildAuditLogMemberRepository(Ref ref) {
  return GuildAuditLogMemberRepository(
    database: ref.watch(starDatabaseProvider),
    client: ref.watch(starClientProvider),
    chunkWaiter: ref.watch(guildMemberChunkWaiterProvider),
    readGateway: () => _readConnectedGateway(ref),
  );
}
