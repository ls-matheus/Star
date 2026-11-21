import 'package:star_app/core/instance/instance_runtime_config.dart';
import 'package:star_app/core/providers/instance/active_instance_provider.dart';
import 'package:star_app/core/providers/instance/well_known_provider.dart';
import 'package:star_dart/export.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'instance_runtime_config_provider.g.dart';

@Riverpod(keepAlive: true)
InstanceRuntimeConfig instanceRuntimeConfig(Ref ref) {
  final AsyncValue<WellKnownStarResponse> wellKnown = ref.watch(
    wellKnownProvider,
  );
  return wellKnown.maybeWhen(
    data: InstanceRuntimeConfig.fromWellKnown,
    orElse: () => InstanceRuntimeConfig.fromWellKnown(
      ref.watch(activeInstanceProvider).wellKnown,
    ),
  );
}

typedef AccountIdentityFlags = ({bool usernameSignIn, bool uniqueUsernames});

@Riverpod(keepAlive: true)
class AccountIdentity extends _$AccountIdentity {
  @override
  AccountIdentityFlags build() {
    return _flagsOf(
      InstanceRuntimeConfig.fromWellKnown(
        ref.read(activeInstanceProvider).wellKnown,
      ),
    );
  }

  void sync(InstanceRuntimeConfig config) {
    final AccountIdentityFlags next = _flagsOf(config);
    if (next != state) {
      state = next;
    }
  }
}

AccountIdentityFlags _flagsOf(InstanceRuntimeConfig config) => (
  usernameSignIn: config.usernameSignIn,
  uniqueUsernames: config.uniqueUsernames,
);

@Riverpod(keepAlive: true)
bool uniqueUsernames(Ref ref) {
  return ref.watch(accountIdentityProvider).uniqueUsernames;
}
