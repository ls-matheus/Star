import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:star_app/core/providers/app/account_user_id.dart';
import 'package:star_app/core/theme/star_theme_extension.dart';
import 'package:star_app/features/guilds/providers/guild_permissions_provider.dart';
import 'package:star_app/features/members/utils/guild_members_page_permissions.dart';
import 'package:star_app/features/ui/spinner/star_loading_spinner.dart';
import 'package:star_app/l10n/generated/star_localizations.dart';
import 'package:star_app/material_ui.dart';

class GuildMembersAccessGate extends ConsumerStatefulWidget {
  const GuildMembersAccessGate({
    required this.guildId,
    required this.child,
    super.key,
  });

  final String guildId;
  final Widget child;

  @override
  ConsumerState<GuildMembersAccessGate> createState() =>
      _GuildMembersAccessGateState();
}

class _GuildMembersAccessGateState
    extends ConsumerState<GuildMembersAccessGate> {
  bool _permissionsResolved = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _resolvePermissions());
  }

  Future<void> _resolvePermissions() async {
    await ref
        .read(guildPermissionsProvider(readAccountUserId(ref)).notifier)
        .refreshPermissions(widget.guildId);
    if (mounted) {
      setState(() => _permissionsResolved = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_permissionsResolved) {
      return const Center(child: StarLoadingSpinner());
    }

    final int permissions =
        ref.watch(
          guildPermissionsProvider(watchAccountUserId(ref)),
        )[widget.guildId] ??
        0;
    if (!hasMembersPagePermission(permissions)) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(context.layout.s4),
          child: Text(
            StarLocalizations.of(context).guildSettingsNoPermission,
            style: context.textStyles.bodySmall,
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return widget.child;
  }
}
