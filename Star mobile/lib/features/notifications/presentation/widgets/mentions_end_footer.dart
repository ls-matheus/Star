import 'package:star_app/core/theme/star_theme_extension.dart';
import 'package:star_app/l10n/generated/star_localizations.dart';
import 'package:star_app/material_ui.dart';

class MentionsEndFooter extends StatelessWidget {
  const MentionsEndFooter({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final textStyles = context.textStyles;
    final StarLocalizations l10n = StarLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(
            l10n.notificationsMentionsEndTitle,
            style: textStyles.channelName.copyWith(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: colors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.notificationsMentionsEndBody,
            style: textStyles.bodyMedium.copyWith(
              color: colors.textPrimaryMuted,
            ),
          ),
        ],
      ),
    );
  }
}
