import 'package:star_app/core/theme/star_theme_extension.dart';
import 'package:star_app/features/settings/domain/guild/guild_discovery_application.dart';
import 'package:star_app/features/settings/presentation/widgets/guild/discovery/guild_discovery_status_badge.dart';
import 'package:star_app/features/settings/presentation/widgets/guild/discovery/guild_discovery_surfaces.dart';
import 'package:star_app/l10n/generated/star_localizations.dart';
import 'package:star_app/material_ui.dart';

class GuildDiscoveryStatusCard extends StatelessWidget {
  const GuildDiscoveryStatusCard({required this.application, super.key});

  final GuildDiscoveryApplication application;

  @override
  Widget build(BuildContext context) {
    final StarLocalizations l10n = StarLocalizations.of(context);
    final String? reason = application.displayReason;
    return Container(
      padding: EdgeInsets.all(context.layout.s4),
      decoration: guildDiscoveryCardDecoration(context.colors, context.layout),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Wrap(
            spacing: context.layout.s2,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: <Widget>[
              Text(
                l10n.guildSettingsDiscoveryStatusLabel,
                style: context.textStyles.bodySmall.copyWith(
                  color: context.colors.textPrimaryMuted,
                ),
              ),
              GuildDiscoveryStatusBadge(status: application.status),
            ],
          ),
          if (reason != null && reason.isNotEmpty) ...<Widget>[
            SizedBox(height: context.layout.s3),
            Text(
              l10n.guildSettingsDiscoveryReason(reason),
              style: context.textStyles.bodySmall.copyWith(
                color: context.colors.textPrimaryMuted,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
