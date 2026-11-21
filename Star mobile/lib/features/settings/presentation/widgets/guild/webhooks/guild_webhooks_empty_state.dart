import 'package:star_app/core/theme/star_theme_extension.dart';
import 'package:star_app/features/channels/utils/webhook_utils.dart';
import 'package:star_app/l10n/generated/star_localizations.dart';
import 'package:star_app/material_ui.dart';
import 'package:star_app/shared/icons/phosphor.dart';

class GuildWebhooksEmptyState extends StatelessWidget {
  const GuildWebhooksEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    final StarLocalizations l10n = StarLocalizations.of(context);
    final String channelSettingsPath = formatChannelSettingsWebhooksPath(l10n);
    return Center(
      child: Padding(
        padding: EdgeInsets.all(context.layout.s8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            PhosphorIcon(
              PhosphorIconsFill.robot,
              size: 40,
              color: context.colors.textPrimaryMuted,
            ),
            SizedBox(height: context.layout.s3),
            Text(
              l10n.guildSettingsWebhooksEmpty,
              style: context.textStyles.bodyMedium.copyWith(
                color: context.colors.textChat,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: context.layout.s1),
            Text(
              l10n.guildSettingsWebhooksEmptyDescription(channelSettingsPath),
              style: context.textStyles.bodyMedium.copyWith(
                color: context.colors.textPrimaryMuted,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
