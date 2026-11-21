import 'package:dio/dio.dart';
import 'package:star_app/core/api/star_client_provider.dart';
import 'package:star_app/core/database/star_database.dart';
import 'package:star_app/core/gateway/gateway_identify_client_properties.dart';
import 'package:star_app/core/observability/star_observability.dart';
import 'package:star_app/core/router/app_location_persistence.dart';
import 'package:star_app/core/router/route_kind.dart';
import 'package:star_app/core/router/route_state_providers.dart';
import 'package:star_dart/gateway.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'gateway_connection_provider.g.dart';

const int kGatewayDebounceMessageReactions = 1 << 1;

const int kGatewayChannelThreads = 1 << 2;

@Riverpod(keepAlive: true)
bool gatewayHasAuthToken(Ref ref) {
  ref.watch(starAuthTokenProvider);
  final String apiBaseUrl = ref.watch(starBaseUrlProvider);
  return ref.read(starAuthTokenProvider.notifier).isIssuedBy(apiBaseUrl);
}

@Riverpod(keepAlive: true)
class IdentifyInitialGuildId extends _$IdentifyInitialGuildId {
  @override
  String? build() => null;

  void set(String? guildId) {
    if (state == guildId) {
      return;
    }
    state = guildId;
  }
}

Future<void> restoreIdentifyInitialGuildId(
  IdentifyInitialGuildId notifier,
  StarDatabase database,
) async {
  final String? location = await readPersistedAppLocation(database);
  notifier.set(location == null ? null : extractGuildId(location));
}

String? readGatewaySessionId(Ref ref) => ref.read(gatewayHasAuthTokenProvider)
    ? ref.read(gatewayConnectionProvider).sessionId
    : null;

@Riverpod(keepAlive: true)
GatewayConnection gatewayConnection(Ref ref) {
  final Dio dio = ref.watch(starDioProvider);
  final bool hasToken = ref.watch(gatewayHasAuthTokenProvider);
  ref.watch(activeInstanceProvider);

  if (!hasToken) {
    throw StateError('Cannot create gateway connection without auth token');
  }

  final String token = ref.read(starAuthTokenProvider)!;
  final clientProperties = ref.read(starClientPropertiesProvider);

  final String? initialGuildId =
      ref.read(activeGuildIdProvider) ??
      ref.read(identifyInitialGuildIdProvider);

  final connection = GatewayConnection(
    token: token,
    dio: dio,
    gatewayUrl: ref.watch(activeInstanceGatewayUrlProvider),
    initialGuildId: initialGuildId,
    flags: kGatewayDebounceMessageReactions | kGatewayChannelThreads,
    traceAsync: StarObservability.instance.traceAsync,
    traceSync: StarObservability.instance.traceSync,
    properties: buildGatewayIdentifyProperties(clientProperties),
  );

  ref.onDispose(connection.dispose);
  return connection;
}
