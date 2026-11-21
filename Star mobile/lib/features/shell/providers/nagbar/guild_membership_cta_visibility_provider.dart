import 'package:star_app/core/api/star_client_provider.dart';
import 'package:star_app/core/providers/instance/well_known_provider.dart';
import 'package:star_app/features/guilds/providers/guild_providers.dart';
import 'package:star_app/features/guilds/utils/invites/invite_code.dart';
import 'package:star_dart/export.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'guild_membership_cta_visibility_provider.g.dart';

const String kStarHqInviteCode = 'star-hq';

@Riverpod(keepAlive: true)
Future<bool> guildMembershipCtaVisible(Ref ref) async {
  final AsyncValue<WellKnownStarResponse> wellKnown = ref.watch(
    wellKnownProvider,
  );
  final bool isSelfHosted = wellKnown.maybeWhen(
    data: (WellKnownStarResponse response) => response.features.selfHosted,
    orElse: () => false,
  );
  if (isSelfHosted) {
    return false;
  }
  try {
    final StarClient client = ref.read(starClientProvider);
    final InviteResponseSchema schema = await client.invites.getInvite(
      inviteCode: kStarHqInviteCode,
    );
    if (!inviteResponseIsGuild(schema)) {
      return false;
    }
    final String guildId = schema.toGuildInviteResponse().guild.id;
    // One-off snapshot; read does not retain the autoDispose family.
    // ignore: riverpod_lint/only_use_keep_alive_inside_keep_alive
    return (await ref.read(guildByIdProvider(guildId).future)) == null;
  } on Object {
    return false;
  }
}
