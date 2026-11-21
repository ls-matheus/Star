import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:star_app/core/theme/star_theme_extension.dart';
import 'package:star_app/features/bookmarks/presentation/widgets/message_list_page_shell.dart';
import 'package:star_app/features/members/presentation/widgets/guild_members_access_gate.dart';
import 'package:star_app/features/members/presentation/widgets/guild_members_desktop_table.dart';
import 'package:star_app/l10n/generated/star_localizations.dart';
import 'package:star_app/material_ui.dart';
import 'package:star_app/shared/icons/phosphor.dart';

class GuildMembersPage extends ConsumerWidget {
  const GuildMembersPage({required this.guildId, super.key});

  final String guildId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final StarLocalizations l10n = StarLocalizations.of(context);
    return MessageListPageShell(
      icon: PhosphorIcon(
        PhosphorIconsFill.users,
        size: 24,
        color: context.colors.textPrimaryMuted,
      ),
      title: l10n.guildMembersChannelListLabel,
      body: GuildMembersAccessGate(
        guildId: guildId,
        child: GuildMembersDesktopTable(guildId: guildId),
      ),
    );
  }
}
