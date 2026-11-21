import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:star_app/core/api/star_client_provider.dart';
import 'package:star_app/core/providers/gateway/gateway_connection_provider.dart';
import 'package:star_app/features/auth/providers/auth_providers.dart';
import 'package:star_app/features/auth/providers/current_auth_session_provider.dart';

Future<void> applyReplacementSession(
  WidgetRef ref, {
  required String token,
  required String authSessionIdHash,
}) async {
  ref.read(gatewayConnectionProvider).setToken(token);
  ref.read(starAuthTokenProvider.notifier).setToken(token);
  ref.read(currentAuthSessionIdHashProvider.notifier).update(authSessionIdHash);
  await ref.read(authRepositoryProvider).persistRotatedToken(token);
}
