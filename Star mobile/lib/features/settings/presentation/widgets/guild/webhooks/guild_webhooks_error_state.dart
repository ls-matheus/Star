import 'package:star_app/core/theme/star_theme_extension.dart';
import 'package:star_app/features/ui/button/star_button.dart';
import 'package:star_app/l10n/generated/star_localizations.dart';
import 'package:star_app/material_ui.dart';
import 'package:star_app/shared/icons/phosphor.dart';

class GuildWebhooksErrorState extends StatelessWidget {
  const GuildWebhooksErrorState({required this.onRetry, super.key});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final StarLocalizations l10n = StarLocalizations.of(context);
    return Center(
      child: Padding(
        padding: EdgeInsets.all(context.layout.s8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            PhosphorIcon(
              PhosphorIconsFill.warningCircle,
              size: 40,
              color: context.colors.textPrimaryMuted,
            ),
            SizedBox(height: context.layout.s3),
            Text(
              l10n.guildSettingsWebhooksLoadFailedTitle,
              style: context.textStyles.bodyMedium.copyWith(
                color: context.colors.textChat,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: context.layout.s1),
            Text(
              l10n.guildSettingsWebhooksLoadFailedDescription,
              style: context.textStyles.bodyMedium.copyWith(
                color: context.colors.textPrimaryMuted,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: context.layout.s4),
            StarButton.primary(
              label: l10n.guildSettingsInvitesTryAgain,
              onPressed: onRetry,
            ),
          ],
        ),
      ),
    );
  }
}
