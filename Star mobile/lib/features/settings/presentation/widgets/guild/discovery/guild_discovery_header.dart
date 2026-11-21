import 'package:star_app/core/theme/star_theme_extension.dart';
import 'package:star_app/features/shell/presentation/responsive_layout.dart';
import 'package:star_app/l10n/generated/star_localizations.dart';
import 'package:star_app/material_ui.dart';

class GuildDiscoveryHeader extends StatelessWidget {
  const GuildDiscoveryHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final StarLocalizations l10n = StarLocalizations.of(context);
    final bool isMobile = isMobileLayout(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        if (!isMobile) ...<Widget>[
          Text(
            l10n.guildMenuSettingsDiscovery,
            style: context.textStyles.heading.copyWith(
              fontSize: 18,
              color: context.colors.textChat,
            ),
          ),
          SizedBox(height: context.layout.s1),
        ],
        Text(
          l10n.guildSettingsDiscoveryDescription,
          style: context.textStyles.bodyMedium.copyWith(
            color: context.colors.textPrimaryMuted,
          ),
        ),
      ],
    );
  }
}
