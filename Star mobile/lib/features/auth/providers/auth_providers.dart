import 'package:star_app/core/api/star_client_provider.dart';
import 'package:star_app/core/providers/database_provider.dart';
import 'package:star_app/features/auth/data/auth_repository.dart';
import 'package:star_app/features/auth/data/auth_token_storage.dart';
import 'package:star_app/features/auth/data/sso_auth_service.dart';
import 'package:star_app/features/auth/providers/auth_instance_snapshot_provider.dart';
import 'package:star_dart/export.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'auth_providers.g.dart';

@Riverpod(keepAlive: true)
AuthTokenStorage authTokenStorage(Ref ref) {
  return SecureAuthTokenStorage();
}

@Riverpod(keepAlive: true)
SsoAuthService ssoAuthService(Ref ref) {
  return SsoAuthService();
}

@Riverpod(keepAlive: true)
AuthRepository authRepository(Ref ref) {
  final StarClient client = ref.watch(authStarClientProvider);
  final db = ref.watch(starDatabaseProvider);
  final tokenStorage = ref.watch(authTokenStorageProvider);
  return AuthRepository(
    client,
    db,
    tokenStorage,
    readInstanceSnapshot: () => ref.read(authInstanceSnapshotProvider),
  );
}
