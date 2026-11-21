import 'package:star_app/core/api/star_client_provider.dart';
import 'package:star_app/core/router/star_router.dart';
import 'package:star_app/features/recovery_kit/domain/recovery_kit.dart';
import 'package:star_app/features/settings/providers/view_models/user_settings_view_model.dart';
import 'package:star_dart/export.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'recovery_kit_providers.g.dart';

@Riverpod(keepAlive: true)
class PendingRecoveryKit extends _$PendingRecoveryKit {
  @override
  RecoveryKit? build() {
    ref.listen<String?>(currentUserIdProvider, (
      String? previous,
      String? next,
    ) {
      if (previous != null && previous != next) {
        state = null;
      }
    });
    return null;
  }

  void present(RecoveryKit kit) {
    if (state == kit) {
      return;
    }
    state = kit;
  }

  void clear() => state = null;

  Future<RecoveryKit> create({
    required RecoveryKitReason reason,
    String? password,
    String? username,
    String? discriminator,
  }) async {
    final RecoveryKitCreateResponse response = await ref
        .read(starClientProvider)
        .users
        .createRecoveryKit(
          body: password == null
              ? const SudoVerificationSchema()
              : SudoVerificationSchema(password: password),
        );
    ref.invalidate(recoveryKitStatusProvider);
    final UserSettingsViewState settings = ref.read(
      userSettingsViewModelProvider,
    );
    final bool fromSettings = username == null && settings.username.isNotEmpty;
    return RecoveryKit(
      recoveryKey: response.recoveryKey,
      createdAt: response.createdAt,
      reason: reason,
      username: fromSettings ? settings.username : username,
      discriminator: fromSettings ? settings.discriminator : discriminator,
    );
  }

  Future<void> createAndPresent({
    required RecoveryKitReason reason,
    String? password,
    String? username,
    String? discriminator,
  }) async {
    present(
      await create(
        reason: reason,
        password: password,
        username: username,
        discriminator: discriminator,
      ),
    );
  }
}

@riverpod
Future<RecoveryKitStatusResponse> recoveryKitStatus(Ref ref) {
  ref.watch(currentUserIdProvider);
  return ref.watch(starClientProvider).users.getRecoveryKitStatus();
}
