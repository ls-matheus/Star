import 'package:star_app/core/api/star_client_provider.dart';
import 'package:star_app/core/gateway/message_mention_context_cache.dart';
import 'package:star_app/core/providers/app/account_user_id.dart';
import 'package:star_app/core/providers/database_provider.dart';
import 'package:star_app/core/providers/gateway/gateway_connection_provider.dart';
import 'package:star_app/core/providers/gateway/gateway_performance_providers.dart';
import 'package:star_app/features/chat/data/message_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'chat_providers.g.dart';

@Riverpod(keepAlive: true)
MessageRepository messageRepository(Ref ref) {
  final client = ref.watch(starClientProvider);
  final dio = ref.watch(starDioProvider);
  final db = ref.watch(starDatabaseProvider);
  final String? currentUserId = accountUserIdOrNull(ref, watch: true);
  final MessageMentionContextCache mentionCache = currentUserId == null
      ? MessageMentionContextCache(database: db)
      : ref.watch(messageMentionContextCacheProvider(currentUserId));
  return MessageRepository(
    client,
    dio,
    db,
    currentUserId,
    mentionContextCache: mentionCache,
    gatewaySessionId: () => readGatewaySessionId(ref),
  );
}
