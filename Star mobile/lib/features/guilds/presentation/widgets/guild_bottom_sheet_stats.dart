import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:star_app/core/providers/gateway/gateway_connection_provider.dart';
import 'package:star_app/core/theme/star_theme_extension.dart';
import 'package:star_app/features/guilds/domain/guild.dart';
import 'package:star_app/features/guilds/providers/guild_list_view_model.dart';
import 'package:star_app/l10n/generated/star_localizations.dart';
import 'package:star_app/material_ui.dart';
import 'package:intl/intl.dart';

class GuildBottomSheetStats extends ConsumerStatefulWidget {
  final String guildId;
  final Guild fallbackGuild;

  const GuildBottomSheetStats({
    required this.guildId,
    required this.fallbackGuild,
    super.key,
  });

  @override
  ConsumerState<GuildBottomSheetStats> createState() =>
      _GuildBottomSheetStatsState();
}

class _GuildBottomSheetStatsState extends ConsumerState<GuildBottomSheetStats> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      try {
        ref.read(gatewayConnectionProvider).requestGuildCounts(<String>[
          widget.guildId,
        ]);
      } on Object {
        // Stats still render from the last stored counts.
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final Guild guild =
        ref.watch(
          guildListViewModelProvider.select(
            (GuildListViewState state) => state.guilds
                .where((Guild g) => g.id == widget.guildId)
                .firstOrNull,
          ),
        ) ??
        widget.fallbackGuild;
    final colors = context.colors;
    final textStyle = context.textStyles.timestamp;
    final StarLocalizations l10n = StarLocalizations.of(context);
    final String onlineCount = NumberFormat.decimalPattern(
      Localizations.localeOf(context).toString(),
    ).format(guild.onlineCount);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _StatDot(color: colors.statusOnline),
        const SizedBox(width: 5),
        Text(
          l10n.discoveryOnlineCount(onlineCount),
          style: textStyle.copyWith(color: colors.textTertiary),
        ),
        const SizedBox(width: 10),
        _StatDot(color: colors.textTertiarySecondary),
        const SizedBox(width: 5),
        Text(
          l10n.discoveryMemberCount(guild.memberCount),
          style: textStyle.copyWith(color: colors.textTertiary),
        ),
      ],
    );
  }
}

class _StatDot extends StatelessWidget {
  final Color color;

  const _StatDot({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}
